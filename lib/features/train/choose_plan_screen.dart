import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/exercise_repository.dart';
import '../../core/services/plan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/plan_templates.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/workout_plan.dart';
import 'build_plan_screen.dart';
import 'import_plan_screen.dart';

/// Plan chooser: a template picked by goal and days per week (rule-based, no
/// AI call), a custom day-by-day builder, or an import from CSV, Excel or PDF.
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key, required this.profile});

  final AppUser profile;

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _creating = false;

  Future<void> _useTemplate() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    setState(() => _creating = true);
    try {
      final goal = widget.profile.goal ?? FitnessGoal.stayFit;
      final daysPerWeek = widget.profile.trainingDaysPerWeek ?? 4;
      final template = PlanTemplates.pick(goal: goal, daysPerWeek: daysPerWeek);

      final planId = await PlanRepository.instance.createPlan(
        userId: userId,
        name: template.name,
        source: PlanSource.ai,
        daysPerWeek: template.days.length,
        durationWeeks: template.durationWeeks,
        level: template.level,
      );

      for (var i = 0; i < template.days.length; i++) {
        final day = template.days[i];
        final dayId = await PlanRepository.instance.addPlanDay(planId: planId, dayIndex: i, label: day.label);
        for (var j = 0; j < day.exercises.length; j++) {
          final te = day.exercises[j];
          final matches = await ExerciseRepository.instance.search(query: te.exerciseName);
          final exercise = matches.where((e) => e.name == te.exerciseName).firstOrNull ?? matches.firstOrNull;
          if (exercise == null) continue;
          await PlanRepository.instance.addPlanExercise(
            planDayId: dayId,
            exerciseId: exercise.id,
            orderIndex: j,
            targetSets: te.sets,
            targetReps: te.reps,
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Your Plan', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _creating
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text('How do you want to train?', style: AppTextStyles.h1.copyWith(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text('Pick one. You can switch plans later.', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  _OptionCard(
                    tag: 'Made for you',
                    title: 'Use our plan',
                    subtitle: 'A plan built from your goal and training frequency.',
                    icon: Icons.auto_awesome_rounded,
                    onTap: _useTemplate,
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    title: 'Build my own',
                    subtitle: 'Choose days and exercises from the library.',
                    icon: Icons.edit_note_rounded,
                    onTap: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const BuildPlanScreen()),
                      );
                      if (created == true && context.mounted) Navigator.of(context).pop(true);
                    },
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    title: 'Import my plan',
                    subtitle: 'Upload a CSV, Excel, or PDF file, or paste a CSV.',
                    icon: Icons.upload_file_rounded,
                    onTap: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const ImportPlanScreen()),
                      );
                      if (created == true && context.mounted) Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.title, required this.subtitle, required this.icon, required this.onTap, this.tag});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.accentSoft,
                        child: Text(tag!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.accentDeep)),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
