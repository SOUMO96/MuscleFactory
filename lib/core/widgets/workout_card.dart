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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: workout.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(workout.icon, color: Colors.white, size: 28),
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
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${workout.durationMinutes} min', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.local_fire_department_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${workout.calories} kcal', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(workout.level, style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: workout.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: workout.gradient.first.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "TODAY'S WORKOUT",
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
                Icon(workout.icon, color: Colors.white, size: 26),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              workout.name,
              style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Text(
                  '${workout.durationMinutes} min',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(width: 14),
                Icon(Icons.local_fire_department_outlined, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Text(
                  '${workout.calories} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Workout',
                    style: AppTextStyles.button.copyWith(color: Colors.black),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
