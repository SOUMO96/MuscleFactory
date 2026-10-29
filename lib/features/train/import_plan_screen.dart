import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/exercise_repository.dart';
import '../../core/services/file_text_extractor.dart';
import '../../core/services/plan_repository.dart';
import '../../core/services/plan_text_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/exercise.dart';
import '../../shared/models/workout_plan.dart';

class _ParsedRow {
  _ParsedRow({required this.day, required this.exerciseName, required this.sets, required this.reps, this.resolvedExercise});
  final String day;
  final String exerciseName;
  final int sets;
  final String reps;

  /// Set when the smart file parser already matched this row to a catalog
  /// exercise, so _save() can skip the name lookup. Pasted-CSV rows are resolved
  /// by name at save time.
  final Exercise? resolvedExercise;
}

/// Import a plan by pasting CSV or uploading a .csv, .xlsx or .pdf file.
/// Uploads go through PlanTextParser (rule-based, no external AI), since real
/// plans aren't always a clean day,exercise,sets,reps table.
class ImportPlanScreen extends StatefulWidget {
  const ImportPlanScreen({super.key});

  @override
  State<ImportPlanScreen> createState() => _ImportPlanScreenState();
}

class _ImportPlanScreenState extends State<ImportPlanScreen> {
  final _nameController = TextEditingController(text: 'Imported Plan');
  final _daysPerWeekController = TextEditingController();
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
  bool _parsingFile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _daysPerWeekController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  /// Removes duplicate exercises within a day (the fuzzy matcher can map two
  /// differently worded rows to the same exercise). If fewer training days are
  /// requested than the source has, extra days are folded in round-robin so no
  /// exercise is dropped.
  List<_ParsedRow> _postProcess(List<_ParsedRow> rows, {int? targetDays}) {
    final dayOrder = <String>[];
    final byDay = <String, List<_ParsedRow>>{};
    for (final r in rows) {
      byDay.putIfAbsent(r.day, () {
        dayOrder.add(r.day);
        return [];
      }).add(r);
    }

    List<String> finalDayOrder;
    Map<String, List<_ParsedRow>> finalByDay;
    if (targetDays != null && targetDays > 0 && targetDays < dayOrder.length) {
      finalDayOrder = List.generate(targetDays, (i) => 'Day ${i + 1}');
      finalByDay = {for (final d in finalDayOrder) d: <_ParsedRow>[]};
      for (var i = 0; i < dayOrder.length; i++) {
        final bucket = finalDayOrder[i % targetDays];
        for (final r in byDay[dayOrder[i]]!) {
          finalByDay[bucket]!.add(_ParsedRow(day: bucket, exerciseName: r.exerciseName, sets: r.sets, reps: r.reps, resolvedExercise: r.resolvedExercise));
        }
      }
    } else {
      finalDayOrder = dayOrder;
      finalByDay = byDay;
    }

    final result = <_ParsedRow>[];
    for (final day in finalDayOrder) {
      final seen = <String>{};
      for (final r in finalByDay[day]!) {
        final key = r.resolvedExercise?.id ?? r.exerciseName.trim().toLowerCase();
        if (!seen.add(key)) continue;
        result.add(r);
      }
    }
    return result;
  }

  int? get _requestedDays => int.tryParse(_daysPerWeekController.text.trim());

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'pdf', 'txt'],
    );
    if (file == null) return;

    setState(() {
      _parsingFile = true;
      _error = null;
      _preview = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final text = FileTextExtractor.extract(bytes: bytes, fileName: file.name);
      final catalog = await ExerciseRepository.instance.search();
      final rows = PlanTextParser.parse(text, catalog);
      if (rows.isEmpty) {
        setState(() => _error = "Couldn't find any recognizable exercises (with sets/reps) in that file.");
        return;
      }
      // Same cap as the paste path: _save() inserts one row at a time, so an
      // oversized file shouldn't be able to queue thousands of inserts.
      const maxRows = 200;
      if (rows.length > maxRows) {
        setState(() => _error = 'That file produced ${rows.length} rows -- more than a real plan would have. Please use a smaller file.');
        return;
      }
      final parsed = rows
          .map((r) => _ParsedRow(day: r.day, exerciseName: r.exercise.name, sets: r.sets, reps: r.reps, resolvedExercise: r.exercise))
          .toList();
      setState(() {
        _preview = _postProcess(parsed, targetDays: _requestedDays);
      });
    } catch (e) {
      setState(() => _error = "Couldn't read that file: ${e is FormatException ? e.message : e}");
    } finally {
      if (mounted) setState(() => _parsingFile = false);
    }
  }

  void _parseCsvText() {
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
    // Hundreds of rows is almost certainly a bad paste, and _save() inserts row
    // by row, so cap it.
    const maxRows = 200;
    if (lines.length - start > maxRows) {
      setState(() {
        _error = 'Too many rows (${lines.length - start}). Paste at most $maxRows.';
        _preview = null;
      });
      return;
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
      _preview = _postProcess(rows, targetDays: _requestedDays);
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
          final exercise = row.resolvedExercise ?? (await ExerciseRepository.instance.search(query: row.exerciseName)).firstOrNull;
          if (exercise == null) continue;
          await PlanRepository.instance.addPlanExercise(
            planDayId: dayId,
            exerciseId: exercise.id,
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
            Text('PLAN NAME', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextField(controller: _nameController),
            const SizedBox(height: 20),
            Text('DAYS PER WEEK (OPTIONAL)', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              "If your file has more day groups than you actually want to train, extra days are folded into "
              "this many -- no exercises are dropped. Leave blank to use the days found as-is.",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _daysPerWeekController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 4'),
            ),
            const SizedBox(height: 20),
            Text('UPLOAD A FILE', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text('CSV, Excel (.xlsx), or PDF. Reads day labels, exercise names, and sets/reps automatically.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            Material(
              color: AppColors.card,
              child: InkWell(
                onTap: _parsingFile ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _parsingFile ? 'Reading file…' : 'Choose a file',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_parsingFile) SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.divider)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR PASTE CSV', style: AppTextStyles.caption)),
                Expanded(child: Divider(color: AppColors.divider)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Columns: day, exercise, sets, reps.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: _csvController,
              maxLines: 8,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _parseCsvText, child: const Text('Preview CSV')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            if (_preview != null) ...[
              Text('Found ${_preview!.length} rows across ${_preview!.map((r) => r.day).toSet().length} days', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              for (final row in _preview!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${row.day} · ${row.exerciseName} · ${row.sets}×${row.reps}', style: AppTextStyles.bodySmall),
                ),
              const SizedBox(height: 20),
              _saving
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Save Plan', icon: Icons.check_rounded, onPressed: _save),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
