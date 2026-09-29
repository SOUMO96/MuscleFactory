import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/workout_session.dart';

class _Achievement {
  const _Achievement({required this.icon, required this.label, required this.description, required this.unlocked});
  final IconData icon;
  final String label;
  final String description;
  final bool unlocked;
}

/// Real achievements computed from actual workout history -- no
/// hardcoded "unlocked: false" placeholders.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<_Achievement> _achievements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final results = await Future.wait([
      WorkoutSessionRepository.instance.history(userId, limit: 1000),
      WorkoutSessionRepository.instance.recentSets(userId, since: DateTime(2000)),
    ]);
    final sessions = (results[0] as List<WorkoutSession>).where((s) => s.isFinished).toList();
    final sets = results[1] as List<LoggedSet>;

    final workoutCount = sessions.length;
    final prCount = sets.where((s) => s.weightKg != null).map((s) => s.exerciseName).toSet().length;

    final days = sessions.map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day)).toSet().toList()..sort();
    var longestStreak = 0;
    var current = 0;
    DateTime? prev;
    for (final day in days) {
      if (prev != null && day.difference(prev).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > longestStreak) longestStreak = current;
      prev = day;
    }

    if (!mounted) return;
    setState(() {
      _achievements = [
        _Achievement(icon: Icons.flag_circle_outlined, label: 'First Workout', description: 'Complete your first workout', unlocked: workoutCount >= 1),
        _Achievement(icon: Icons.local_fire_department_outlined, label: '7 Day Streak', description: 'Train 7 days in a row', unlocked: longestStreak >= 7),
        _Achievement(icon: Icons.repeat_rounded, label: '10 Workouts', description: 'Complete 10 workouts', unlocked: workoutCount >= 10),
        _Achievement(icon: Icons.emoji_events_outlined, label: '50 Workouts', description: 'Complete 50 workouts', unlocked: workoutCount >= 50),
        _Achievement(icon: Icons.whatshot_rounded, label: '30 Day Streak', description: 'Train 30 days in a row', unlocked: longestStreak >= 30),
        _Achievement(icon: Icons.military_tech_outlined, label: 'First PR', description: 'Log your first personal record', unlocked: prCount >= 1),
        _Achievement(icon: Icons.workspace_premium_outlined, label: '5 PRs', description: 'Set personal records in 5 exercises', unlocked: prCount >= 5),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Achievements', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : GridView.count(
                padding: const EdgeInsets.all(20),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: _achievements.map((a) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: a.unlocked ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
                      border: Border.all(color: a.unlocked ? AppColors.primary : AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a.icon, color: a.unlocked ? AppColors.primary : AppColors.textMuted, size: 28),
                        const Spacer(),
                        Text(a.label, style: AppTextStyles.h3.copyWith(color: a.unlocked ? AppColors.textPrimary : AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(a.description, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
