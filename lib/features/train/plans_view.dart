import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/plan_repository.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
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
  Map<String, int> _doneCountByDay = {};
  String? _todayDayId;
  int _thisWeekDone = 0;
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

    var doneCountByDay = <String, int>{};
    String? todayDayId;
    var thisWeekDone = 0;
    if (plan != null && days.isNotEmpty) {
      final sessions = (await WorkoutSessionRepository.instance.history(userId, limit: 500))
          .where((s) => s.isFinished && s.planDayId != null && days.any((d) => d.id == s.planDayId))
          .toList();

      for (final day in days) {
        doneCountByDay[day.id] = sessions.where((s) => s.planDayId == day.id).length;
      }
      todayDayId = days[sessions.length % days.length].id;

      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      thisWeekDone = sessions
          .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
          .where((d) => !d.isBefore(startOfWeek))
          .toSet()
          .length;
    }

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _days = days;
      _doneCountByDay = doneCountByDay;
      _todayDayId = todayDayId;
      _thisWeekDone = thisWeekDone;
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

  Future<void> _deletePlan(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${plan.name}"?', style: AppTextStyles.h3),
        content: Text(
          'This removes the plan and its days. Workouts you already logged stay in your history.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await PlanRepository.instance.deletePlan(plan.id);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Couldn't delete the plan. Try again."), backgroundColor: AppColors.error),
      );
    }
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

    final weekProgress = plan.daysPerWeek == 0 ? 0.0 : (_thisWeekDone / plan.daysPerWeek).clamp(0, 1).toDouble();

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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('THIS WEEK', style: AppTextStyles.caption),
                  Text('$_thisWeekDone of ${plan.daysPerWeek} done', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                child: LinearProgressIndicator(
                  value: weekProgress,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('THIS PLAN', style: AppTextStyles.caption),
        const SizedBox(height: 10),
        for (final day in _days)
          _DayRow(
            day: day,
            isToday: day.id == _todayDayId,
            timesDone: _doneCountByDay[day.id] ?? 0,
            onStart: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(planDayId: day.id, dayLabel: day.label)),
              );
              _load();
            },
          ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _chooseNewPlan,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Choose a different plan',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _deletePlan(plan),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Delete plan',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.isToday, required this.timesDone, required this.onStart});

  final PlanDay day;
  final bool isToday;
  final int timesDone;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(border: Border.all(color: isToday ? AppColors.primary : AppColors.divider, width: isToday ? 2 : 1)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(day.label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.accentSoft,
                        child: Text('TODAY', style: AppTextStyles.caption.copyWith(color: AppColors.accentDeep)),
                      ),
                    ],
                  ],
                ),
                if (timesDone > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Done ${timesDone == 1 ? "once" : "$timesDone times"}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isToday)
            Material(
              color: AppColors.primary,
              child: InkWell(
                onTap: onStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('Start', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.background, fontWeight: FontWeight.w700)),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onStart,
              child: Text('Start', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
