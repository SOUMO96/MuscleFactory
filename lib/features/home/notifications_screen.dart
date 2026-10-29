import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/class_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/gym_class.dart';
import '../../shared/models/workout_session.dart';

class _NotificationItem {
  const _NotificationItem({required this.icon, required this.title, required this.subtitle, required this.time});
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime time;
}

/// An activity feed built from existing data (classes booked today, workouts
/// finished this week, recent PRs); there's no notifications table.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotificationItem> _items = [];
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
      ClassRepository.instance.myBookings(userId),
      ClassRepository.instance.upcoming(),
      WorkoutSessionRepository.instance.history(userId, limit: 50),
      WorkoutSessionRepository.instance.recentSets(userId, since: DateTime.now().subtract(const Duration(days: 7))),
    ]);
    final myBookings = results[0] as List<ClassBooking>;
    final upcoming = results[1] as List<GymClass>;
    final sessions = (results[2] as List<WorkoutSession>).where((s) => s.isFinished).toList();
    final recentSets = results[3] as List<LoggedSet>;

    final bookedIds = myBookings.where((b) => b.status == BookingStatus.booked).map((b) => b.classId).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = <_NotificationItem>[];

    for (final c in upcoming.where((c) => bookedIds.contains(c.id))) {
      final classDay = DateTime(c.startsAt.year, c.startsAt.month, c.startsAt.day);
      if (classDay == today) {
        items.add(_NotificationItem(
          icon: Icons.calendar_month_outlined,
          title: '${c.name} today',
          subtitle: 'You\'re booked for ${c.startsAt.hour.toString().padLeft(2, '0')}:${c.startsAt.minute.toString().padLeft(2, '0')} at ${c.location}',
          time: c.startsAt,
        ));
      }
    }

    for (final s in sessions.where((s) => s.startedAt.isAfter(now.subtract(const Duration(days: 7))))) {
      items.add(_NotificationItem(
        icon: Icons.check_circle_outline_rounded,
        title: 'Workout completed',
        subtitle: s.planDayLabel ?? 'Freestyle workout',
        time: s.startedAt,
      ));
    }

    final bestByExercise = <String, double>{};
    for (final s in recentSets) {
      final name = s.exerciseName;
      if (name == null || s.weightKg == null) continue;
      if (s.weightKg! > (bestByExercise[name] ?? 0)) {
        bestByExercise[name] = s.weightKg!;
        items.add(_NotificationItem(
          icon: Icons.military_tech_outlined,
          title: 'New personal record',
          subtitle: '$name · ${s.weightKg} kg',
          time: s.completedAt,
        ));
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('You\'re all caught up.', style: AppTextStyles.bodyMedium)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              color: AppColors.surfaceVariant,
                              child: Icon(item.icon, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                  Text(item.subtitle, style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
