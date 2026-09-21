import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/workout_card.dart';
import '../../shared/data/dummy_data.dart';
import '../../shared/models/app_user.dart';
import '../workouts/workout_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = DummyData.workouts.first;
    final recommended = DummyData.workouts.skip(1).take(4).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const _Header(),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '0',
                    label: 'Calories burned',
                    accentColor: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    icon: Icons.timer_rounded,
                    value: '0 min',
                    label: 'Active time',
                    accentColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '0 days',
                    label: 'Current streak',
                    accentColor: AppColors.warning,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    icon: Icons.flag_rounded,
                    value: '0/5',
                    label: 'Weekly goal',
                    accentColor: Color(0xFF2E7CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FeaturedWorkoutCard(
              workout: featured,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(workout: featured)),
              ),
            ),
            const SizedBox(height: 28),
            const _QuickActionsRow(),
            const SizedBox(height: 28),
            SectionHeader(
                title: 'Recommended For You',
                actionLabel: 'See all',
                onAction: () {}),
            const SizedBox(height: 14),
            ...recommended.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WorkoutCard(
                  workout: w,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => WorkoutDetailScreen(workout: w)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        Row(
          children: [
            _IconBadge(icon: Icons.notifications_none_rounded, onTap: () {}),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: AppTextStyles.h3.copyWith(color: AppColors.background),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (icon: Icons.monitor_weight_outlined, label: 'Log Weight'),
      (icon: Icons.water_drop_outlined, label: 'Water'),
      (icon: Icons.restaurant_outlined, label: 'Add Meal'),
      (icon: Icons.timer_outlined, label: 'Timer'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (a) => Column(
              children: [
                Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
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
