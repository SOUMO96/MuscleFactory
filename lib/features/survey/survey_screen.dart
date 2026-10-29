import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/app_user.dart';

enum _HeightUnit { cm, ft }

const _pageCount = 8;

/// One-time survey after a user's first sign-in, one question per page: name,
/// age, gender, height, weight, goal, target weight and duration, training
/// days. Writes the answers to the profile row and marks the survey done.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  late final TextEditingController _nameController;

  int _age = 25;
  String? _gender;
  FitnessGoal? _goal;
  bool _loading = false;

  _HeightUnit _unit = _HeightUnit.cm;
  int _heightCm = 170;
  int _feet = 5;
  int _inches = 7;

  double _currentWeightKg = 70;
  double _targetWeightKg = 70;
  int _durationWeeks = 12;
  int _trainingDaysPerWeek = 4;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      UserRepository.instance.getUserProfile(user.id).then((profile) {
        if (!mounted || profile == null) return;
        _nameController.text = profile.displayName == 'Athlete' ? '' : profile.displayName;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  double get _heightInCm {
    if (_unit == _HeightUnit.cm) return _heightCm.toDouble();
    return (_feet * 30.48) + (_inches * 2.54);
  }

  void _selectGoal(FitnessGoal goal) {
    setState(() {
      _goal = goal;
      // Suggest a sensible starting target the user can fine-tune.
      switch (goal) {
        case FitnessGoal.gainWeight:
          _targetWeightKg = _currentWeightKg + 5;
        case FitnessGoal.loseWeight:
          _targetWeightKg = (_currentWeightKg - 5).clamp(30, 300);
        case FitnessGoal.stayFit:
          _targetWeightKg = _currentWeightKg;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_pageIndex == 0 && _nameController.text.trim().isEmpty) {
      _showError('Enter your name.');
      return;
    }
    if (_pageIndex == 2 && _gender == null) {
      _showError('Select your gender.');
      return;
    }
    _goToPage(_pageIndex + 1);
  }

  void _back() => _goToPage(_pageIndex - 1);

  Future<void> _submit() async {
    if (_goal == null) {
      _showError('Select your goal.');
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showError('You have been signed out. Please log in again.');
      return;
    }

    final name = _nameController.text.trim();

    setState(() => _loading = true);
    try {
      await UserRepository.instance.saveSurveyResults(
        uid: user.id,
        name: name,
        age: _age,
        gender: _gender!,
        heightCm: _heightInCm,
        currentWeightKg: _currentWeightKg,
        goal: _goal!,
        targetWeightKg: _targetWeightKg,
        goalDurationWeeks: _durationWeeks,
        trainingDaysPerWeek: _trainingDaysPerWeek,
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
    final isLast = _pageIndex == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: _pageIndex > 0
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: _back,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (i) {
                        final active = i == _pageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.divider,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _QuestionPage(
                    icon: Icons.badge_outlined,
                    title: "What's your name?",
                    subtitle: "Let's personalize your experience.",
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2,
                      decoration: const InputDecoration(hintText: 'Your name'),
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.cake_outlined,
                    title: 'How old are you?',
                    subtitle: 'This helps us tailor your plan.',
                    child: _Stepper(
                      value: _age.toDouble(),
                      unit: 'years',
                      min: 13,
                      max: 99,
                      step: 1,
                      onChanged: (v) => setState(() => _age = v.round()),
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.wc_rounded,
                    title: "What's your gender?",
                    subtitle: 'Select the option that fits best.',
                    child: Column(
                      children: [
                        _OptionTile(
                          label: 'Male',
                          selected: _gender == 'Male',
                          onTap: () => setState(() => _gender = 'Male'),
                        ),
                        const SizedBox(height: 12),
                        _OptionTile(
                          label: 'Female',
                          selected: _gender == 'Female',
                          onTap: () => setState(() => _gender = 'Female'),
                        ),
                        const SizedBox(height: 12),
                        _OptionTile(
                          label: 'Other',
                          selected: _gender == 'Other',
                          onTap: () => setState(() => _gender = 'Other'),
                        ),
                      ],
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.height_rounded,
                    title: "What's your height?",
                    subtitle: 'Switch units any time.',
                    child: Column(
                      children: [
                        _UnitToggle(unit: _unit, onChanged: (u) => setState(() => _unit = u)),
                        const SizedBox(height: 24),
                        if (_unit == _HeightUnit.cm)
                          _Stepper(
                            value: _heightCm.toDouble(),
                            unit: 'cm',
                            min: 100,
                            max: 230,
                            step: 1,
                            onChanged: (v) => setState(() => _heightCm = v.round()),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _Stepper(
                                  value: _feet.toDouble(),
                                  unit: 'ft',
                                  min: 3,
                                  max: 7,
                                  step: 1,
                                  onChanged: (v) => setState(() => _feet = v.round()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Stepper(
                                  value: _inches.toDouble(),
                                  unit: 'in',
                                  min: 0,
                                  max: 11,
                                  step: 1,
                                  onChanged: (v) => setState(() => _inches = v.round()),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.monitor_weight_outlined,
                    title: "What's your current weight?",
                    subtitle: 'Your starting point.',
                    child: _Stepper(
                      value: _currentWeightKg,
                      unit: 'kg',
                      min: 30,
                      max: 200,
                      step: 0.5,
                      onChanged: (v) => setState(() => _currentWeightKg = v),
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.flag_rounded,
                    title: "What's your goal?",
                    subtitle: "We'll tailor your plan around this.",
                    child: Column(
                      children: [
                        _GoalCard(
                          icon: Icons.trending_up_rounded,
                          label: FitnessGoal.gainWeight.label,
                          subtitle: 'Build muscle and increase body weight',
                          selected: _goal == FitnessGoal.gainWeight,
                          onTap: () => _selectGoal(FitnessGoal.gainWeight),
                        ),
                        const SizedBox(height: 10),
                        _GoalCard(
                          icon: Icons.trending_down_rounded,
                          label: FitnessGoal.loseWeight.label,
                          subtitle: 'Burn fat and reduce body weight',
                          selected: _goal == FitnessGoal.loseWeight,
                          onTap: () => _selectGoal(FitnessGoal.loseWeight),
                        ),
                        const SizedBox(height: 10),
                        _GoalCard(
                          icon: Icons.favorite_rounded,
                          label: FitnessGoal.stayFit.label,
                          subtitle: 'Maintain your current shape and health',
                          selected: _goal == FitnessGoal.stayFit,
                          onTap: () => _selectGoal(FitnessGoal.stayFit),
                        ),
                      ],
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.emoji_events_outlined,
                    title: 'Set your target',
                    subtitle: 'What weight, and by when?',
                    child: Column(
                      children: [
                        Text('TARGET WEIGHT', style: AppTextStyles.caption),
                        const SizedBox(height: 10),
                        _Stepper(
                          value: _targetWeightKg,
                          unit: 'kg',
                          min: 30,
                          max: 200,
                          step: 0.5,
                          onChanged: (v) => setState(() => _targetWeightKg = v),
                        ),
                        const SizedBox(height: 24),
                        Text('TIMEFRAME', style: AppTextStyles.caption),
                        const SizedBox(height: 10),
                        _Stepper(
                          value: _durationWeeks.toDouble(),
                          unit: 'weeks',
                          min: 1,
                          max: 52,
                          step: 1,
                          onChanged: (v) => setState(() => _durationWeeks = v.round()),
                        ),
                      ],
                    ),
                  ),
                  _QuestionPage(
                    icon: Icons.event_repeat_rounded,
                    title: 'Training days per week',
                    subtitle: "How often do you want to train? You can change this later.",
                    child: _Stepper(
                      value: _trainingDaysPerWeek.toDouble(),
                      unit: 'days / week',
                      min: 1,
                      max: 6,
                      step: 1,
                      onChanged: (v) => setState(() => _trainingDaysPerWeek = v.round()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(
                      label: isLast ? 'Finish Setup' : 'Continue',
                      icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      onPressed: isLast ? _submit : _next,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(icon, color: AppColors.background, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.h1.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 36),
          child,
        ],
      ),
    );
  }
}

/// A -/+ stepper for a numeric value. Supports fractional [step]s (e.g.
/// 0.5 for weight); the displayed value drops the decimal when [step] is
/// a whole number.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepButton(Icons.remove_rounded, value > min ? () => onChanged(value - step) : null),
          Column(
            children: [
              Text(_display, style: AppTextStyles.display.copyWith(fontSize: 40)),
              Text(unit, style: AppTextStyles.bodyMedium),
            ],
          ),
          _stepButton(Icons.add_rounded, value < max ? () => onChanged(value + step) : null),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceVariant,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(icon, color: enabled ? AppColors.primary : AppColors.textMuted, size: 24),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.h3.copyWith(color: selected ? AppColors.background : AppColors.textPrimary),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
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
