import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/class_repository.dart';
import '../../core/services/nutrition_repository.dart';
import '../../core/services/plan_repository.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/gym_class.dart';
import '../../shared/models/workout_plan.dart';
import '../../shared/models/workout_session.dart';
import '../nutrition/nutrition_screen.dart';
import '../train/active_workout_screen.dart';
import '../train/train_screen.dart';
import 'log_weight_sheet.dart';
import 'timer_sheet.dart';

/// Home dashboard -- a direct copy of the design's "02 Home" screen, now
/// backed entirely by real data: today's workout from the active plan,
/// a real weekly completion grid, real stats, the next booked class, and
/// today's nutrition total. Replaces the earlier version, which showed
/// unrelated dummy workout-library cards instead of the user's actual
/// plan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutPlan? _plan;
  PlanDay? _todayDay;
  int _todayExerciseCount = 0;
  List<DateTime> _finishedDaysThisWeek = [];
  int _streak = 0;
  double _volume7d = 0;
  int _minutes7d = 0;
  GymClass? _nextClass;
  int _caloriesToday = 0;
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

    final results = await Future.wait([
      WorkoutSessionRepository.instance.history(userId, limit: 500),
      WorkoutSessionRepository.instance.recentSets(userId, since: DateTime.now().subtract(const Duration(days: 7))),
      ClassRepository.instance.myBookings(userId),
      ClassRepository.instance.upcoming(),
      NutritionRepository.instance.entriesForDate(userId, DateTime.now()),
    ]);
    final sessions = (results[0] as List<WorkoutSession>).where((s) => s.isFinished).toList();
    final sets = results[1] as List<dynamic>;
    final myBookings = results[2] as List<ClassBooking>;
    final upcomingClasses = results[3] as List<GymClass>;
    final nutritionEntries = results[4] as List<dynamic>;

    PlanDay? todayDay;
    var todayExerciseCount = 0;
    if (days.isNotEmpty) {
      final finishedForPlan = sessions.where((s) => days.any((d) => d.id == s.planDayId)).length;
      todayDay = days[finishedForPlan % days.length];
      final exercises = await PlanRepository.instance.getPlanExercises(todayDay.id);
      todayExerciseCount = exercises.length;
    }

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final finishedDaysThisWeek = sessions
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .where((d) => !d.isBefore(startOfWeek))
        .toSet()
        .toList();

    var streak = 0;
    var day = now;
    final finishedDaySet = sessions.map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day)).toSet();
    while (finishedDaySet.contains(DateTime(day.year, day.month, day.day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    final volume7d = sets.fold(0.0, (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 0)));
    final minutes7d = sessions
        .where((s) => s.startedAt.isAfter(now.subtract(const Duration(days: 7))) && s.endedAt != null)
        .fold(0, (sum, s) => sum + s.endedAt!.difference(s.startedAt).inMinutes);

    final bookedClassIds = myBookings.where((b) => b.status == BookingStatus.booked).map((b) => b.classId).toSet();
    final nextClass = upcomingClasses.where((c) => bookedClassIds.contains(c.id)).firstOrNull;

    final caloriesToday = nutritionEntries.fold(0, (sum, e) => sum + (e.calories as int));

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _todayDay = todayDay;
      _todayExerciseCount = todayExerciseCount;
      _finishedDaysThisWeek = finishedDaysThisWeek;
      _streak = streak;
      _volume7d = volume7d;
      _minutes7d = minutes7d;
      _nextClass = nextClass;
      _caloriesToday = caloriesToday;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    const _Header(),
                    const SizedBox(height: 24),
                    _HeroCard(plan: _plan, day: _todayDay, exerciseCount: _todayExerciseCount, onFinished: _load),
                    const SizedBox(height: 24),
                    _WeekGrid(finishedDays: _finishedDaysThisWeek),
                    const SizedBox(height: 20),
                    StatRow(
                      children: [
                        StatCell(value: '$_streak', label: 'Day streak'),
                        StatCell(value: '${_volume7d.round()}kg', label: 'Volume · 7 days'),
                        StatCell(value: '${(_minutes7d / 60).toStringAsFixed(1)}h', label: 'Hours · 7 days'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_nextClass != null) _UpcomingClassRow(gymClass: _nextClass!),
                    const SizedBox(height: 20),
                    _NutritionRow(calories: _caloriesToday),
                    const SizedBox(height: 28),
                    _QuickActionsRow(onWeightLogged: _load),
                  ],
                ),
              ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<AppUser?>(
      stream: UserRepository.instance.watchUserProfile(user.id),
      builder: (context, snapshot) {
        final displayName =
            (snapshot.data?.displayName.trim().isNotEmpty ?? false)
                ? snapshot.data!.displayName
                : 'Athlete';
        final firstName = displayName.split(RegExp(r'\s+')).first;
        final initials = displayName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

        return _HeaderContent(firstName: firstName, initials: initials);
      },
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.firstName, required this.initials});
  final String firstName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning 👋', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(firstName, style: AppTextStyles.h1.copyWith(fontSize: 22)),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          color: AppColors.primary,
          alignment: Alignment.center,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: AppTextStyles.h3.copyWith(color: AppColors.background),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.plan, required this.day, required this.exerciseCount, required this.onFinished});
  final WorkoutPlan? plan;
  final PlanDay? day;
  final int exerciseCount;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    if (plan == null || day == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No active plan yet', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Choose a plan to see today\'s workout here.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Go to Train',
              icon: Icons.arrow_forward_rounded,
              expand: false,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrainScreen())),
            ),
          ],
        ),
      );
    }

    final estimatedMinutes = exerciseCount * 8;
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY · ${plan!.name.toUpperCase()}', style: AppTextStyles.caption.copyWith(color: AppColors.background)),
          const SizedBox(height: 8),
          Text(day!.label, style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 32)),
          const SizedBox(height: 6),
          Text('$exerciseCount exercises · ~$estimatedMinutes min', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.background.withValues(alpha: 0.8))),
          const SizedBox(height: 18),
          Material(
            color: AppColors.textPrimary,
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(planDayId: day!.id, dayLabel: day!.label)),
                );
                onFinished();
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start workout', style: AppTextStyles.button.copyWith(color: AppColors.background)),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.background, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.finishedDays});
  final List<DateTime> finishedDays;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    return Row(
      children: List.generate(7, (i) {
        final day = startOfWeek.add(Duration(days: i));
        final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
        final done = finishedDays.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 6 ? 0 : 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: isToday ? AppColors.primary : AppColors.divider, width: isToday ? 2 : 1)),
            child: Column(
              children: [
                Text(_labels[i], style: AppTextStyles.caption.copyWith(color: isToday ? AppColors.primary : AppColors.textMuted)),
                const SizedBox(height: 8),
                Container(height: 12, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 2), color: done ? AppColors.textPrimary : Colors.transparent),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _UpcomingClassRow extends StatelessWidget {
  const _UpcomingClassRow({required this.gymClass});
  final GymClass gymClass;

  @override
  Widget build(BuildContext context) {
    final hh = gymClass.startsAt.hour.toString().padLeft(2, '0');
    final mm = gymClass.startsAt.minute.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Text('$hh:$mm', style: AppTextStyles.h3),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${gymClass.name} — booked', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                Text(gymClass.location, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.calories});
  final int calories;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('$calories kcal logged today', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onWeightLogged});
  final VoidCallback onWeightLogged;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.monitor_weight_outlined,
        label: 'Log Weight',
        onTap: () async {
          final logged = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: AppColors.surface,
            isScrollControlled: true,
            builder: (_) => const LogWeightSheet(),
          );
          if (logged == true) onWeightLogged();
        },
      ),
      (
        icon: Icons.water_drop_outlined,
        label: 'Water',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionScreen())),
      ),
      (
        icon: Icons.restaurant_outlined,
        label: 'Add Meal',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionScreen())),
      ),
      (
        icon: Icons.timer_outlined,
        label: 'Timer',
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          isScrollControlled: true,
          builder: (_) => const TimerSheet(),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (a) => Column(
              children: [
                Material(
                  color: AppColors.card,
                  child: InkWell(
                    onTap: a.onTap,
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                      child: Icon(a.icon, color: AppColors.primary, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(a.label, style: AppTextStyles.bodySmall),
              ],
            ),
          )
          .toList(),
    );
  }
}
