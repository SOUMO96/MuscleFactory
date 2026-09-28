import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/plan_repository.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/workout_plan.dart';
import 'active_workout_screen.dart';
import 'choose_plan_screen.dart';

/// Default view of the Train tab: the user's active plan (if any) with
/// its days and a Start action per day, or a prompt to choose a plan.
class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  WorkoutPlan? _plan;
  List<PlanDay> _days = [];
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
    final plan = await PlanRepository.instance.getActivePlan(userId);
    final days = plan == null ? <PlanDay>[] : await PlanRepository.instance.getPlanDays(plan.id);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _days = days;
      _loading = false;
    });
  }

  Future<void> _chooseNewPlan() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final profile = await UserRepository.instance.getUserProfile(userId);
    if (!mounted || profile == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChoosePlanScreen(profile: profile)),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.primary));

    final plan = _plan;
    if (plan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_rounded, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No active plan yet', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Choose a plan to start tracking workouts.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Choose Your Plan', icon: Icons.arrow_forward_rounded, onPressed: _chooseNewPlan, expand: false),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE PLAN', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(plan.name, style: AppTextStyles.h1.copyWith(fontSize: 22)),
              const SizedBox(height: 2),
              Text(
                '${plan.daysPerWeek} days / week'
                '${plan.level != null ? ' · ${plan.level}' : ''}'
                '${plan.durationWeeks != null ? ' · ${plan.durationWeeks} weeks' : ''}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('THIS PLAN', style: AppTextStyles.caption),
        const SizedBox(height: 10),
        for (final day in _days)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                Expanded(child: Text(day.label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700))),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(planDayId: day.id, dayLabel: day.label)),
                    );
                  },
                  child: Text('Start', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _chooseNewPlan,
          icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
          label: Text('Choose a different plan', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}
