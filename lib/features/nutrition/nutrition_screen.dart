import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/nutrition_repository.dart';
import '../../core/services/water_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/nutrition_entry.dart';

/// General daily water-intake guideline (2L) -- not personalized, shown
/// as a plain target rather than fabricated per-user data.
const _waterGoalMl = 2000;

/// Real manual meal/macro logging for today -- no food database search,
/// matching the redesign plan's explicit scope for this screen.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<NutritionEntry> _entries = [];
  int _waterMl = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      NutritionRepository.instance.entriesForDate(userId, DateTime.now()),
      WaterRepository.instance.totalForDate(userId, DateTime.now()),
    ]);
    if (!mounted) return;
    setState(() {
      _entries = results[0] as List<NutritionEntry>;
      _waterMl = results[1] as int;
      _loading = false;
    });
  }

  Future<void> _addWater(int amountMl) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    await WaterRepository.instance.addWater(userId: userId, date: DateTime.now(), amountMl: amountMl);
    _load();
  }

  Future<void> _addMeal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => const _AddMealSheet(),
    );
    if (result == true) _load();
  }

  Future<void> _delete(NutritionEntry entry) async {
    await NutritionRepository.instance.deleteEntry(entry.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _entries.fold(0, (sum, e) => sum + e.calories);
    final totalProtein = _entries.fold(0.0, (sum, e) => sum + (e.proteinG ?? 0));
    final totalCarbs = _entries.fold(0.0, (sum, e) => sum + (e.carbsG ?? 0));
    final totalFat = _entries.fold(0.0, (sum, e) => sum + (e.fatG ?? 0));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nutrition', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                      Text('Today', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('$totalCalories', style: AppTextStyles.display.copyWith(fontSize: 44)),
                  Text('kcal today', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider, width: 2), bottom: BorderSide(color: AppColors.divider, width: 2))),
                    child: Row(
                      children: [
                        Expanded(child: _MacroCell(label: 'Protein', value: totalProtein)),
                        Container(width: 1, height: 48, color: AppColors.divider),
                        Expanded(child: _MacroCell(label: 'Carbs', value: totalCarbs)),
                        Container(width: 1, height: 48, color: AppColors.divider),
                        Expanded(child: _MacroCell(label: 'Fat', value: totalFat)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Water', style: AppTextStyles.bodySmall),
                            Text('${(_waterMl / 1000).toStringAsFixed(1)} / ${(_waterGoalMl / 1000).toStringAsFixed(1)} L', style: AppTextStyles.h3),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _addWater(250),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('+250ml', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRect(
                    child: LinearProgressIndicator(
                      value: (_waterMl / _waterGoalMl).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('Nothing logged yet today.', style: AppTextStyles.bodyMedium),
                    )
                  else
                    for (final e in _entries)
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.mealLabel, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                          subtitle: Text('${e.calories} kcal', style: AppTextStyles.bodySmall),
                          trailing: IconButton(
                            icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () => _delete(e),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Log Meal', icon: Icons.add_rounded, onPressed: _addMeal),
                ],
              ),
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text('${value.round()}g', style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _labelController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = AuthService.instance.currentUser?.id;
    final calories = int.tryParse(_caloriesController.text.trim());
    if (userId == null || _labelController.text.trim().isEmpty || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Enter a meal name and calories.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await NutritionRepository.instance.addEntry(
        userId: userId,
        entryDate: DateTime.now(),
        mealLabel: _labelController.text.trim(),
        calories: calories,
        proteinG: double.tryParse(_proteinController.text.trim()),
        carbsG: double.tryParse(_carbsController.text.trim()),
        fatG: double.tryParse(_fatController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Meal', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            TextField(controller: _labelController, decoration: const InputDecoration(hintText: 'Meal (e.g. Lunch)')),
            const SizedBox(height: 10),
            TextField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Calories')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _proteinController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Protein g'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _carbsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Carbs g'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _fatController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Fat g'))),
              ],
            ),
            const SizedBox(height: 20),
            _saving
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PrimaryButton(label: 'Save', icon: Icons.check_rounded, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
