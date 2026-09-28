import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/exercise_repository.dart';
import '../../core/services/plan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/exercise.dart';
import '../../shared/models/workout_plan.dart';

class _ExerciseDraft {
  _ExerciseDraft({required this.exercise, required this.sets, required this.reps});
  final Exercise exercise;
  int sets;
  String reps;
}

class _DayDraft {
  _DayDraft({required this.label});
  String label;
  final List<_ExerciseDraft> exercises = [];
}

/// "Build my own": pick a number of training days, then add exercises
/// (with sets/reps) to each day from the real exercise library -- a
/// genuinely functional plan builder, not a mockup.
class BuildPlanScreen extends StatefulWidget {
  const BuildPlanScreen({super.key});

  @override
  State<BuildPlanScreen> createState() => _BuildPlanScreenState();
}

class _BuildPlanScreenState extends State<BuildPlanScreen> {
  final _nameController = TextEditingController(text: 'My Plan');
  final List<_DayDraft> _days = [_DayDraft(label: 'Day 1')];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addDay() {
    if (_days.length >= 6) return;
    setState(() => _days.add(_DayDraft(label: 'Day ${_days.length + 1}')));
  }

  void _removeDay(int index) {
    if (_days.length <= 1) return;
    setState(() => _days.removeAt(index));
  }

  Future<void> _addExercise(_DayDraft day) async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => const _ExercisePickerSheet(),
    );
    if (picked == null) return;
    setState(() => day.exercises.add(_ExerciseDraft(exercise: picked, sets: 3, reps: '10')));
  }

  Future<void> _save() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    if (_days.every((d) => d.exercises.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Add at least one exercise.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final planId = await PlanRepository.instance.createPlan(
        userId: userId,
        name: _nameController.text.trim().isEmpty ? 'My Plan' : _nameController.text.trim(),
        source: PlanSource.custom,
        daysPerWeek: _days.length,
      );
      for (var i = 0; i < _days.length; i++) {
        final day = _days[i];
        final dayId = await PlanRepository.instance.addPlanDay(planId: planId, dayIndex: i, label: day.label);
        for (var j = 0; j < day.exercises.length; j++) {
          final ex = day.exercises[j];
          await PlanRepository.instance.addPlanExercise(
            planDayId: dayId,
            exerciseId: ex.exercise.id,
            orderIndex: j,
            targetSets: ex.sets,
            targetReps: ex.reps,
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Build My Own', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text('PLAN NAME', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  TextField(controller: _nameController),
                  const SizedBox(height: 20),
                  for (var i = 0; i < _days.length; i++) _DaySection(day: _days[i], onAddExercise: () => _addExercise(_days[i]), onRemove: () => _removeDay(i)),
                  const SizedBox(height: 8),
                  if (_days.length < 6)
                    TextButton.icon(
                      onPressed: _addDay,
                      icon: Icon(Icons.add_rounded, color: AppColors.primary),
                      label: Text('Add another day', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _saving
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Save Plan', icon: Icons.check_rounded, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatefulWidget {
  const _DaySection({required this.day, required this.onAddExercise, required this.onRemove});
  final _DayDraft day;
  final VoidCallback onAddExercise;
  final VoidCallback onRemove;

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.day.label,
                    style: AppTextStyles.h3,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (v) => widget.day.label = v,
                  ),
                ),
                IconButton(icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18), onPressed: widget.onRemove),
              ],
            ),
          ),
          for (final ex in widget.day.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(ex.exercise.name, style: AppTextStyles.bodyMedium)),
                  _MiniStepper(value: ex.sets, onChanged: (v) => setState(() => ex.sets = v)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: TextFormField(
                      initialValue: ex.reps,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      onChanged: (v) => ex.reps = v,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: GestureDetector(
              onTap: widget.onAddExercise,
              child: Row(
                children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Add exercise', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(onTap: () => onChanged((value - 1).clamp(1, 10)), child: Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textMuted)),
        SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium)),
        GestureDetector(onTap: () => onChanged((value + 1).clamp(1, 10)), child: Icon(Icons.add_circle_outline, size: 18, color: AppColors.textMuted)),
      ],
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  List<Exercise> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await ExerciseRepository.instance.search(query: query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(hintText: 'Search exercises', prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted)),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, i) {
                      final e = _results[i];
                      return ListTile(
                        title: Text(e.name, style: AppTextStyles.bodyLarge),
                        subtitle: Text('${e.category} · ${e.equipment}', style: AppTextStyles.bodySmall),
                        onTap: () => Navigator.of(context).pop(e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
