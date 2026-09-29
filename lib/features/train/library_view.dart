import 'package:flutter/material.dart';

import '../../core/services/exercise_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/exercise.dart';

/// Real, searchable/filterable exercise browser over the `exercises`
/// catalog -- replaces the old dummy-data workout list.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _query = '';
  String _category = 'All';
  List<String> _categories = ['All'];
  List<Exercise> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final categories = await ExerciseRepository.instance.listCategories();
    if (!mounted) return;
    setState(() => _categories = ['All', ...categories]);
    await _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final results = await ExerciseRepository.instance.search(query: _query, category: _category);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TextField(
            onChanged: (v) {
              _query = v;
              _search();
            },
            decoration: InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: _categories.map((c) {
              final selected = c == _category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _category = c);
                    _search();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.textPrimary : Colors.transparent,
                      border: Border.all(color: selected ? AppColors.textPrimary : AppColors.divider),
                    ),
                    child: Text(
                      c,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selected ? AppColors.background : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _results.isEmpty
                  ? Center(child: Text('No exercises found.', style: AppTextStyles.bodyMedium))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, i) {
                        final e = _results[i];
                        return InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            backgroundColor: AppColors.surface,
                            builder: (_) => _ExerciseDetailSheet(exercise: e),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text('${e.category} · ${e.equipment}', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ExerciseDetailSheet extends StatelessWidget {
  const _ExerciseDetailSheet({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(exercise.name, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                child: Text(exercise.category.toUpperCase(), style: AppTextStyles.caption),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                child: Text(exercise.equipment.toUpperCase(), style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            exercise.description.isEmpty ? 'No description yet.' : exercise.description,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
