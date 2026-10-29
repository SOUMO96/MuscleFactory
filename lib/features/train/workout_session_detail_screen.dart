import 'package:flutter/material.dart';

import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stat_card.dart';
import '../../shared/models/workout_session.dart';

/// Opened from a row in Train -> History; shows the sets logged in that workout.
class WorkoutSessionDetailScreen extends StatefulWidget {
  const WorkoutSessionDetailScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  State<WorkoutSessionDetailScreen> createState() => _WorkoutSessionDetailScreenState();
}

class _WorkoutSessionDetailScreenState extends State<WorkoutSessionDetailScreen> {
  List<LoggedSet> _sets = [];
  bool _loading = true;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sets = await WorkoutSessionRepository.instance.setsForSession(widget.session.id);
    if (!mounted) return;
    setState(() {
      _sets = sets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final duration = s.endedAt?.difference(s.startedAt);

    final byExercise = <String, List<LoggedSet>>{};
    for (final set in _sets) {
      byExercise.putIfAbsent(set.exerciseName ?? 'Exercise', () => []).add(set);
    }
    final totalVolume = _sets.fold<double>(0, (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 0)));

    return Scaffold(
      appBar: AppBar(title: Text(s.planDayLabel ?? 'Freestyle workout', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Text(
                    '${s.startedAt.day} ${_months[s.startedAt.month - 1]} ${s.startedAt.year}'
                    '${duration != null ? ' · ${duration.inMinutes} min' : ''}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  StatRow(
                    children: [
                      StatCell(value: '${_sets.length}', label: 'Sets logged'),
                      StatCell(value: '${byExercise.length}', label: 'Exercises'),
                      StatCell(value: '${totalVolume.round()}kg', label: 'Volume'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_sets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text('No sets were logged in this session.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                    )
                  else
                    for (final entry in byExercise.entries) ...[
                      Text(entry.key, style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                        child: Column(
                          children: [
                            for (var i = 0; i < entry.value.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: i == entry.value.length - 1
                                    ? null
                                    : BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                                child: Row(
                                  children: [
                                    Text('Set ${entry.value[i].setIndex}', style: AppTextStyles.bodyMedium),
                                    const Spacer(),
                                    Text(
                                      '${entry.value[i].weightKg ?? 0} kg × ${entry.value[i].reps ?? 0}',
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                ],
              ),
      ),
    );
  }
}
