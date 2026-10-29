import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/favorite_food_repository.dart';
import '../../core/services/food_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/food.dart';
import 'food_quantity_sheet.dart';

/// Food search: the local catalog first (Indian staples plus cached USDA
/// results), then live USDA via the food-search Edge Function when local
/// results are sparse. Pops `true` if a food was logged.
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> with SingleTickerProviderStateMixin {
  final _queryController = TextEditingController();
  Timer? _debounce;
  List<Food> _results = [];
  List<Food> _favorites = [];
  Set<String> _favoriteIds = {};
  bool _loading = false;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final results = await Future.wait([
      FavoriteFoodRepository.instance.list(userId),
      FavoriteFoodRepository.instance.favoriteIds(userId),
    ]);
    if (!mounted) return;
    setState(() {
      _favorites = results[0] as List<Food>;
      _favoriteIds = results[1] as Set<String>;
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastQuery = trimmed;
    });
    final local = await FoodRepository.instance.searchLocal(trimmed);
    if (!mounted || _lastQuery != trimmed) return;
    setState(() {
      _results = local;
      _loading = local.length >= 5 ? false : true;
    });
    if (local.length >= 5) return;

    try {
      final usda = await FoodRepository.instance.searchUsda(trimmed);
      if (!mounted || _lastQuery != trimmed) return;
      final seen = local.map((f) => f.id).toSet();
      setState(() {
        _results = [...local, ...usda.where((f) => !seen.contains(f.id))];
      });
    } catch (_) {
      // USDA lookup failed (offline, rate-limited, misconfigured key...) --
      // the local results already shown still stand on their own.
    } finally {
      if (mounted && _lastQuery == trimmed) setState(() => _loading = false);
    }
  }

  Future<void> _openFood(Food food) async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FoodQuantitySheet(food: food)),
    );
    if (logged == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _toggleFavorite(Food food) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final isFav = _favoriteIds.contains(food.id);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(food.id);
      } else {
        _favoriteIds.add(food.id);
      }
    });
    if (isFav) {
      await FavoriteFoodRepository.instance.remove(userId: userId, foodId: food.id);
    } else {
      await FavoriteFoodRepository.instance.add(userId: userId, foodId: food.id);
    }
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final showingSearch = _lastQuery != null;
    return Scaffold(
      appBar: AppBar(title: Text('Add food', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _queryController,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Search a food (e.g. Dal, Chicken breast)',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: !showingSearch
                  ? _FavoritesList(favorites: _favorites, onTap: _openFood, onToggleFavorite: _toggleFavorite, favoriteIds: _favoriteIds)
                  : _loading && _results.isEmpty
                      ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  "No foods found for \"$_lastQuery\". Try a different spelling, or log it manually from the Nutrition screen.",
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                              itemCount: _results.length + (_loading ? 1 : 0),
                              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
                              itemBuilder: (context, i) {
                                if (i == _results.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                  );
                                }
                                final food = _results[i];
                                return _FoodRow(
                                  food: food,
                                  isFavorite: _favoriteIds.contains(food.id),
                                  onTap: () => _openFood(food),
                                  onToggleFavorite: () => _toggleFavorite(food),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.favorites, required this.onTap, required this.onToggleFavorite, required this.favoriteIds});
  final List<Food> favorites;
  final ValueChanged<Food> onTap;
  final ValueChanged<Food> onToggleFavorite;
  final Set<String> favoriteIds;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Search for a food above. Foods you star appear here for quick re-logging.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('FAVORITES', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        for (final food in favorites) ...[
          _FoodRow(food: food, isFavorite: true, onTap: () => onTap(food), onToggleFavorite: () => onToggleFavorite(food)),
          Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.isFavorite, required this.onTap, required this.onToggleFavorite});
  final Food food;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${food.category ?? (food.source == 'usda' ? 'USDA' : 'Food')} · ${food.caloriesPer100g.round()} kcal · ${food.proteinPer100g.round()}g protein / 100g',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: isFavorite ? AppColors.primary : AppColors.textMuted),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}
