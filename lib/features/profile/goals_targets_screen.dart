import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/app_user.dart';

/// Lets a user view and edit their fitness goal, target weight and
/// timeframe -- the same fields the survey collects, editable afterward.
class GoalsTargetsScreen extends StatefulWidget {
  const GoalsTargetsScreen({super.key, required this.profile});

  final AppUser profile;

  @override
  State<GoalsTargetsScreen> createState() => _GoalsTargetsScreenState();
}

class _GoalsTargetsScreenState extends State<GoalsTargetsScreen> {
  FitnessGoal? _goal;
  late double _targetWeightKg;
  late int _durationWeeks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.profile.goal;
    _targetWeightKg = widget.profile.targetWeightKg ?? widget.profile.currentWeightKg ?? 70;
    _durationWeeks = widget.profile.goalDurationWeeks ?? 12;
  }

  Future<void> _save() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || _goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Select a goal.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await UserRepository.instance.updateGoal(
        uid: userId,
        goal: _goal!,
        targetWeightKg: _targetWeightKg,
        goalDurationWeeks: _durationWeeks,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Goals & Targets', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text('GOAL', style: AppTextStyles.caption),
            const SizedBox(height: 10),
            for (final goal in FitnessGoal.values) ...[
              _GoalTile(goal: goal, selected: _goal == goal, onTap: () => setState(() => _goal = goal)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            Text('TARGET WEIGHT', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            _Stepper(value: _targetWeightKg, unit: 'kg', min: 30, max: 200, step: 0.5, onChanged: (v) => setState(() => _targetWeightKg = v)),
            const SizedBox(height: 20),
            Text('TIMEFRAME', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            _Stepper(value: _durationWeeks.toDouble(), unit: 'weeks', min: 1, max: 52, step: 1, onChanged: (v) => setState(() => _durationWeeks = v.round())),
            const SizedBox(height: 24),
            _saving
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PrimaryButton(label: 'Save', icon: Icons.check_rounded, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.selected, required this.onTap});
  final FitnessGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Text(
          goal.label,
          style: AppTextStyles.h3.copyWith(color: selected ? AppColors.background : AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.unit, required this.min, required this.max, required this.step, required this.onChanged});
  final double value;
  final String unit;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  String get _display => step >= 1 ? value.round().toString() : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _btn(Icons.remove_rounded, value > min ? () => onChanged(value - step) : null),
          Column(
            children: [
              Text(_display, style: AppTextStyles.display.copyWith(fontSize: 34)),
              Text(unit, style: AppTextStyles.bodyMedium),
            ],
          ),
          _btn(Icons.add_rounded, value < max ? () => onChanged(value + step) : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: enabled ? AppColors.primary : AppColors.textMuted)),
      ),
    );
  }
}
