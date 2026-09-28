import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/exercise_repository.dart';
import '../../core/services/plan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/workout_plan.dart';

class _ParsedRow {
  _ParsedRow({required this.day, required this.exerciseName, required this.sets, required this.reps});
  final String day;
  final String exerciseName;
  final int sets;
  final String reps;
}

/// "Import my plan": a real CSV import (paste, not a file upload --
/// simpler on web and avoids a new file-picker dependency for the same
/// result). Expected columns: day, exercise, sets, reps. XLSX/PDF/photo
/// import is out of scope (would need third-party parsing/OCR services
/// this project doesn't have) -- this is the honest, working subset.
class ImportPlanScreen extends StatefulWidget {
  const ImportPlanScreen({super.key});

  @override
  State<ImportPlanScreen> createState() => _ImportPlanScreenState();
}

class _ImportPlanScreenState extends State<ImportPlanScreen> {
  final _nameController = TextEditingController(text: 'Imported Plan');
  final _csvController = TextEditingController(
    text: 'day,exercise,sets,reps\n'
        'Push,Barbell Bench Press,4,8\n'
        'Push,Overhead Press,3,10\n'
        'Pull,Deadlift,3,5\n'
        'Pull,Barbell Row,4,8\n',
  );
  List<_ParsedRow>? _preview;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  void _parse() {
    final lines = _csvController.text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      setState(() {
        _error = 'Paste some CSV rows first.';
        _preview = null;
      });
      return;
    }
    var start = 0;
    if (lines.first.toLowerCase().contains('day') && lines.first.toLowerCase().contains('exercise')) {
      start = 1;
    }
    final rows = <_ParsedRow>[];
    for (var i = start; i < lines.length; i++) {
      final cols = lines[i].split(',').map((c) => c.trim()).toList();
      if (cols.length < 4) continue;
      final sets = int.tryParse(cols[2]);
      if (sets == null) continue;
      rows.add(_ParsedRow(day: cols[0], exerciseName: cols[1], sets: sets, reps: cols[3]));
    }
    if (rows.isEmpty) {
      setState(() {
        _error = 'Could not read any rows. Expected columns: day, exercise, sets, reps.';
        _preview = null;
      });
      return;
    }
    setState(() {
      _preview = rows;
      _error = null;
    });
  }

  Future<void> _save() async {
    final preview = _preview;
    final userId = AuthService.instance.currentUser?.id;
    if (preview == null || userId == null) return;

    setState(() => _saving = true);
    try {
      final dayOrder = <String>[];
      for (final r in preview) {
        if (!dayOrder.contains(r.day)) dayOrder.add(r.day);
      }

      final planId = await PlanRepository.instance.createPlan(
        userId: userId,
        name: _nameController.text.trim().isEmpty ? 'Imported Plan' : _nameController.text.trim(),
        source: PlanSource.import,
        daysPerWeek: dayOrder.length,
      );

      for (var i = 0; i < dayOrder.length; i++) {
        final dayLabel = dayOrder[i];
        final dayId = await PlanRepository.instance.addPlanDay(planId: planId, dayIndex: i, label: dayLabel);
        final dayRows = preview.where((r) => r.day == dayLabel).toList();
        for (var j = 0; j < dayRows.length; j++) {
          final row = dayRows[j];
          final matches = await ExerciseRepository.instance.search(query: row.exerciseName);
          if (matches.isEmpty) continue;
          await PlanRepository.instance.addPlanExercise(
            planDayId: dayId,
            exerciseId: matches.first.id,
            orderIndex: j,
            targetSets: row.sets,
            targetReps: row.reps,
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
      appBar: AppBar(title: Text('Import My Plan', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Paste CSV rows: day, exercise, sets, reps. Exercise names are matched against the library.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('PLAN NAME', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextField(controller: _nameController),
            const SizedBox(height: 16),
            Text('CSV', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextField(
              controller: _csvController,
              maxLines: 8,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            if (_preview != null) ...[
              Text('Found ${_preview!.length} rows across ${_preview!.map((r) => r.day).toSet().length} days', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              for (final row in _preview!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${row.day} · ${row.exerciseName} · ${row.sets}×${row.reps}', style: AppTextStyles.bodySmall),
                ),
              const SizedBox(height: 20),
            ],
            _saving
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PrimaryButton(
                    label: _preview == null ? 'Preview' : 'Save Plan',
                    icon: _preview == null ? Icons.visibility_outlined : Icons.check_rounded,
                    onPressed: _preview == null ? _parse : _save,
                  ),
          ],
        ),
      ),
    );
  }
}
