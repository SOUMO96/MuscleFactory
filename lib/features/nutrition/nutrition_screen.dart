import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/food_repository.dart';
import '../../core/services/nutrition_repository.dart';
import '../../core/services/water_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/nutrition_entry.dart';
import 'food_quantity_sheet.dart';
import 'food_search_screen.dart';
import 'nutrition_history_screen.dart';

/// General daily water-intake guideline (2L) -- not personalized, shown
/// as a plain target rather than fabricated per-user data.
const _waterGoalMl = 2000;

/// Non-personalized reference daily targets (same honesty tradeoff as the
/// water goal above) -- used only to size the progress bars, not claimed
/// as a tailored plan.
const _calorieGoal = 2200.0;
const _proteinGoalG = 150.0;
const _carbsGoalG = 250.0;
const _fatGoalG = 70.0;

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

  Future<void> _logFood() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => const _LogChoiceSheet(),
    );
    if (choice == null || !mounted) return;
    bool? result;
    if (choice == 'search') {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
      );
    } else if (choice == 'manual') {
      result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        builder: (context) => const _ManualEntrySheet(),
      );
    }
    if (result == true) _load();
  }

  Future<void> _editEntry(NutritionEntry entry) async {
    if (entry.foodId == null) return; // manual entries: delete + re-add instead of editing in place
    final food = await FoodRepository.instance.getById(entry.foodId!);
    if (food == null || !mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodQuantitySheet(food: food, editingEntryId: entry.id, initialQuantityG: entry.quantityG),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(NutritionEntry entry) async {
    await NutritionRepository.instance.deleteEntry(entry.id);
    _load();
  }

  Future<void> _copyYesterday() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    await NutritionRepository.instance.copyDay(
      userId: userId,
      fromDate: DateTime.now().subtract(const Duration(days: 1)),
      toDate: DateTime.now(),
    );
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
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nutrition', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionHistoryScreen())),
                          child: Row(
                            children: [
                              Text('History', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ProgressRow(
                      label: 'Calories',
                      value: totalCalories.toDouble(),
                      goal: _calorieGoal,
                      unit: 'kcal',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _ProgressRow(label: 'Protein', value: totalProtein, goal: _proteinGoalG, unit: 'g', compact: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _ProgressRow(label: 'Carbs', value: totalCarbs, goal: _carbsGoalG, unit: 'g', compact: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _ProgressRow(label: 'Fat', value: totalFat, goal: _fatGoalG, unit: 'g', compact: true)),
                      ],
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
                    const SizedBox(height: 28),
                    if (_entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: _copyYesterday,
                          child: Row(
                            children: [
                              Icon(Icons.content_copy_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text("Copy yesterday's food", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    _FoodLogSection(
                      entries: _entries,
                      onAdd: _logFood,
                      onDelete: _delete,
                      onEdit: _editEntry,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value, required this.goal, required this.unit, this.compact = false});
  final String label;
  final double value;
  final double goal;
  final String unit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = goal == 0 ? 0.0 : (value / goal).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: compact ? AppTextStyles.h3 : AppTextStyles.display.copyWith(fontSize: 32),
            children: [
              TextSpan(text: '${value.round()}'),
              TextSpan(text: '/${goal.round()}$unit', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        ClipRect(
          child: LinearProgressIndicator(value: progress, minHeight: compact ? 4 : 6, backgroundColor: AppColors.surfaceVariant, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _FoodLogSection extends StatelessWidget {
  const _FoodLogSection({required this.entries, required this.onAdd, required this.onDelete, required this.onEdit});
  final List<NutritionEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<NutritionEntry> onDelete;
  final ValueChanged<NutritionEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryButton(label: 'Add food', icon: Icons.add_rounded, onPressed: onAdd),
          const SizedBox(height: 20),
          Text("TODAY'S FOOD", style: AppTextStyles.caption),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Text('Nothing logged yet.', style: AppTextStyles.bodySmall),
            )
          else
            for (final e in entries)
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: e.foodId != null ? () => onEdit(e) : null,
                  title: Text(e.foodName ?? e.mealLabel, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    e.quantityG != null ? '${e.quantityG!.round()}g · ${e.calories} kcal' : '${e.calories} kcal',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () => onDelete(e),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _LogChoiceSheet extends StatelessWidget {
  const _LogChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add food', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            _ChoiceRow(icon: Icons.search_rounded, label: 'Search a food', subtitle: 'Pick a quantity, we calculate the rest', onTap: () => Navigator.of(context).pop('search')),
            _ChoiceRow(icon: Icons.edit_outlined, label: 'Enter manually', subtitle: 'Type calories and macros yourself', onTap: () => Navigator.of(context).pop('manual')),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.icon, required this.label, required this.subtitle, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _labelController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // An inline message, not a SnackBar: this sheet sits above the page's Scaffold,
  // so a SnackBar would render underneath it and never be seen.
  void _showError(String message) {
    setState(() => _error = message);
  }

  Future<void> _save() async {
    if (_error != null) setState(() => _error = null);
    final userId = AuthService.instance.currentUser?.id;
    final calories = int.tryParse(_caloriesController.text.trim());
    if (userId == null || _labelController.text.trim().isEmpty || calories == null) {
      _showError('Enter a food name and calories.');
      return;
    }
    if (calories <= 0 || calories > 20000) {
      _showError('Calories must be between 1 and 20000.');
      return;
    }
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());
    for (final macro in [protein, carbs, fat]) {
      if (macro != null && (macro < 0 || macro > 2000)) {
        _showError('Protein, carbs, and fat must be between 0 and 2000g.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await NutritionRepository.instance.addEntry(
        userId: userId,
        entryDate: DateTime.now(),
        mealLabel: _labelController.text.trim(),
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _showError("Couldn't save that meal. Try again.");
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
            Text('Log food', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              const SizedBox(height: 10),
            ],
            TextField(controller: _labelController, decoration: const InputDecoration(hintText: 'Food (e.g. Home-made dal rice)')),
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
