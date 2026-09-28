import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/workout.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(workout: workout),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About this workout', style: AppTextStyles.h2),
                    const SizedBox(height: 10),
                    Text(
                      workout.description,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercises', style: AppTextStyles.h2),
                        Text('${workout.exercises.length} total', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(workout.exercises.length, (i) {
                      final e = workout.exercises[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.name, style: AppTextStyles.h3),
                                    const SizedBox(height: 2),
                                    Text(e.detail, style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                              Icon(e.icon, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                    _CircleIconButton(icon: Icons.favorite_border_rounded, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: PrimaryButton(
                  label: 'Start Workout',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: workout.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(workout.icon, color: Colors.white, size: 44),
          const SizedBox(height: 14),
          Text(
            workout.name,
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaChip(icon: Icons.timer_outlined, label: '${workout.durationMinutes} min'),
              const SizedBox(width: 10),
              _MetaChip(icon: Icons.local_fire_department_outlined, label: '${workout.calories} kcal'),
              const SizedBox(width: 10),
              _MetaChip(icon: Icons.bar_chart_rounded, label: workout.level),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
