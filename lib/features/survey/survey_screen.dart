import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/app_user.dart';

enum _HeightUnit { cm, ft }

/// One-time onboarding survey shown right after a user's first successful
/// sign-up/sign-in (see UserRepository.ensureProfile). Collects the basics
/// needed to personalize the app, then writes them to the user's Firestore
/// profile and marks the survey complete.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  late final TextEditingController _nameController;

  int _age = 25;
  String? _gender;
  FitnessGoal? _goal;
  bool _loading = false;

  _HeightUnit _unit = _HeightUnit.cm;
  int _heightCm = 170;
  int _feet = 5;
  int _inches = 7;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _heightInCm {
    if (_unit == _HeightUnit.cm) return _heightCm.toDouble();
    return (_feet * 30.48) + (_inches * 2.54);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Enter your name.');
      return;
    }
    if (_gender == null) {
      _showError('Select your gender.');
      return;
    }
    if (_goal == null) {
      _showError('Select your goal.');
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showError('You have been signed out. Please log in again.');
      return;
    }

    setState(() => _loading = true);
    try {
      await UserRepository.instance.saveSurveyResults(
        uid: user.uid,
        name: name,
        age: _age,
        gender: _gender!,
        heightCm: _heightInCm,
        goal: _goal!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      _showError('Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell Us About You', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'This helps us personalize your workouts and goals.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text('NAME', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              Text('AGE', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              _Stepper(
                value: _age,
                unit: 'years',
                min: 13,
                max: 99,
                onChanged: (v) => setState(() => _age = v),
              ),
              const SizedBox(height: 24),
              Text('GENDER', style: AppTextStyles.caption),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Male',
                      selected: _gender == 'Male',
                      onTap: () => setState(() => _gender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Female',
                      selected: _gender == 'Female',
                      onTap: () => setState(() => _gender = 'Female'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Other',
                      selected: _gender == 'Other',
                      onTap: () => setState(() => _gender = 'Other'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('HEIGHT', style: AppTextStyles.caption),
                  _UnitToggle(
                    unit: _unit,
                    onChanged: (u) => setState(() => _unit = u),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_unit == _HeightUnit.cm)
                _Stepper(
                  value: _heightCm,
                  unit: 'cm',
                  min: 100,
                  max: 230,
                  onChanged: (v) => setState(() => _heightCm = v),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _Stepper(
                        value: _feet,
                        unit: 'ft',
                        min: 3,
                        max: 7,
                        onChanged: (v) => setState(() => _feet = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stepper(
                        value: _inches,
                        unit: 'in',
                        min: 0,
                        max: 11,
                        onChanged: (v) => setState(() => _inches = v),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text('YOUR GOAL', style: AppTextStyles.caption),
              const SizedBox(height: 10),
              _GoalCard(
                icon: Icons.trending_up_rounded,
                label: FitnessGoal.gainWeight.label,
                subtitle: 'Build muscle and increase body weight',
                selected: _goal == FitnessGoal.gainWeight,
                onTap: () => setState(() => _goal = FitnessGoal.gainWeight),
              ),
              const SizedBox(height: 10),
              _GoalCard(
                icon: Icons.trending_down_rounded,
                label: FitnessGoal.loseWeight.label,
                subtitle: 'Burn fat and reduce body weight',
                selected: _goal == FitnessGoal.loseWeight,
                onTap: () => setState(() => _goal = FitnessGoal.loseWeight),
              ),
              const SizedBox(height: 10),
              _GoalCard(
                icon: Icons.favorite_rounded,
                label: FitnessGoal.stayFit.label,
                subtitle: 'Maintain your current shape and health',
                selected: _goal == FitnessGoal.stayFit,
                onTap: () => setState(() => _goal = FitnessGoal.stayFit),
              ),
              const SizedBox(height: 32),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Finish Setup', icon: Icons.arrow_forward_rounded, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepButton(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
          Column(
            children: [
              Text('$value', style: AppTextStyles.h1.copyWith(fontSize: 22)),
              Text(unit, style: AppTextStyles.bodySmall),
            ],
          ),
          _stepButton(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: enabled ? AppColors.primary : AppColors.textMuted, size: 22),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.background : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});
  final _HeightUnit unit;
  final ValueChanged<_HeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('cm', _HeightUnit.cm),
          _segment('ft', _HeightUnit.ft),
        ],
      ),
    );
  }

  Widget _segment(String label, _HeightUnit value) {
    final selected = unit == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? AppColors.background : AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
