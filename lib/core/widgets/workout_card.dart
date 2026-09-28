import 'package:flutter/material.dart';

import '../../shared/models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A horizontal list-style card for a [Workout] — used in the Workouts
/// library and recommendation rails.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              color: workout.gradient.first,
              child: Icon(workout.icon, color: AppColors.background, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: AppTextStyles.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${workout.durationMinutes} min', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${workout.calories} kcal', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                    child: Text(workout.level.toUpperCase(), style: AppTextStyles.caption),
                  ),
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

/// A larger "hero" card for a featured / scheduled workout on the Home
/// dashboard, with a prominent Start action.
class FeaturedWorkoutCard extends StatelessWidget {
  const FeaturedWorkoutCard({super.key, required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S WORKOUT",
                  style: AppTextStyles.caption.copyWith(color: AppColors.background),
                ),
                Icon(workout.icon, color: AppColors.background, size: 26),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              workout.name,
              style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 15, color: AppColors.background.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
                Text(
                  '${workout.durationMinutes} min',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.background.withValues(alpha: 0.75)),
                ),
                const SizedBox(width: 14),
                Icon(Icons.local_fire_department_outlined, size: 15, color: AppColors.background.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
                Text(
                  '${workout.calories} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.background.withValues(alpha: 0.75)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: AppColors.textPrimary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Workout',
                    style: AppTextStyles.button.copyWith(color: AppColors.background),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.background),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
