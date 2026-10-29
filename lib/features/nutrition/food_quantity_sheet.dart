import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/nutrition_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/food.dart';

const _quickGrams = [50, 100, 150, 250, 500];

/// Quantity entry with live nutrition values for [food]: value per 100g times
/// grams / 100, recalculated on every keystroke. Pops `true` once logged.
class FoodQuantitySheet extends StatefulWidget {
  const FoodQuantitySheet({super.key, required this.food, this.editingEntryId, this.initialQuantityG});

  final Food food;

  /// Set when editing an already-logged entry's quantity instead of
  /// adding a new one.
  final String? editingEntryId;

  /// The entry's previously logged quantity, when editing -- pre-fills the
  /// field instead of resetting it back to the 100g default.
  final double? initialQuantityG;

  @override
  State<FoodQuantitySheet> createState() => _FoodQuantitySheetState();
}

class _FoodQuantitySheetState extends State<FoodQuantitySheet> {
  late final _gramsController = TextEditingController(
    text: widget.initialQuantityG != null ? _formatGrams(widget.initialQuantityG!) : '100',
  );
  bool _saving = false;

  static String _formatGrams(double grams) => grams.truncateToDouble() == grams ? grams.toStringAsFixed(0) : grams.toString();

  double get _grams => double.tryParse(_gramsController.text.trim()) ?? 0;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  Future<void> _save() async {
    final grams = _grams;
    final userId = AuthService.instance.currentUser?.id;
    if (grams <= 0 || grams > 10000) {
      _showError('Enter a quantity between 1g and 10000g.');
      return;
    }
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final food = widget.food;
      final calories = food.caloriesFor(grams).round();
      final protein = food.proteinFor(grams);
      final carbs = food.carbsFor(grams);
      final fat = food.fatFor(grams);

      if (widget.editingEntryId != null) {
        await NutritionRepository.instance.updateQuantity(
          id: widget.editingEntryId!,
          quantityG: grams,
          calories: calories,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
        );
      } else {
        await NutritionRepository.instance.addEntry(
          userId: userId,
          entryDate: DateTime.now(),
          mealLabel: food.name,
          calories: calories,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          foodId: food.id,
          quantityG: grams,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _showError("Couldn't save that entry. Try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final grams = _grams;

    return Scaffold(
      appBar: AppBar(title: Text(food.name, style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (food.brand != null) Text(food.brand!, style: AppTextStyles.bodyMedium),
            Text(
              '${food.category ?? 'Food'} · ${food.source == 'usda' ? 'USDA verified' : 'Reference value'}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('QUANTITY (GRAMS)', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _gramsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(suffixText: 'g'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in _quickGrams)
                  _QuickGramChip(grams: g, selected: grams == g, onTap: () => setState(() => _gramsController.text = '$g')),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FOR ${grams > 0 ? grams.toStringAsFixed(grams.truncateToDouble() == grams ? 0 : 1) : "0"}G', style: AppTextStyles.caption),
                  const SizedBox(height: 10),
                  Text('${food.caloriesFor(grams).round()} kcal', style: AppTextStyles.display.copyWith(fontSize: 32)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _MacroStat(label: 'Protein', grams: food.proteinFor(grams))),
                      Expanded(child: _MacroStat(label: 'Carbs', grams: food.carbsFor(grams))),
                      Expanded(child: _MacroStat(label: 'Fat', grams: food.fatFor(grams))),
                    ],
                  ),
                  if (food.fiberPer100g != null || food.sugarPer100g != null || food.sodiumMgPer100g != null) ...[
                    const SizedBox(height: 14),
                    Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (food.fiberPer100g != null) Expanded(child: _MacroStat(label: 'Fiber', grams: food.fiberFor(grams)!)),
                        if (food.sugarPer100g != null) Expanded(child: _MacroStat(label: 'Sugar', grams: food.sugarFor(grams)!)),
                        if (food.sodiumMgPer100g != null) Expanded(child: _MacroStat(label: 'Sodium', grams: food.sodiumFor(grams)!, unit: 'mg')),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _saving
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PrimaryButton(
                    label: widget.editingEntryId != null ? 'Save Changes' : 'Add food',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
          ],
        ),
      ),
    );
  }
}

class _QuickGramChip extends StatelessWidget {
  const _QuickGramChip({required this.grams, required this.selected, required this.onTap});
  final int grams;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          '${grams}g',
          style: AppTextStyles.bodySmall.copyWith(color: selected ? AppColors.background : AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({required this.label, required this.grams, this.unit = 'g'});
  final String label;
  final double grams;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${grams.round()}$unit', style: AppTextStyles.h3),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
