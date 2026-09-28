import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/plan_repository.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/workout_plan.dart';

/// Real set logger for a plan day: starts a workout_sessions row, lets the
/// user log weight/reps per set against each prescribed exercise (writing
/// to logged_sets), runs a rest timer between sets using the user's
/// default_rest_seconds preference, and marks the session finished.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.planDayId, required this.dayLabel});

  final String planDayId;
  final String dayLabel;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _LoggedEntry {
  _LoggedEntry({required this.weight, required this.reps});
  final double weight;
  final int reps;
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  String? _sessionId;
  List<PlanExercise> _exercises = [];
  bool _loading = true;
  int _restSeconds = 90;

  final Map<String, List<_LoggedEntry>> _logged = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, TextEditingController> _repsControllers = {};

  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final results = await Future.wait([
      WorkoutSessionRepository.instance.startSession(userId: userId, planDayId: widget.planDayId),
      PlanRepository.instance.getPlanExercises(widget.planDayId),
      UserRepository.instance.getUserProfile(userId),
    ]);
    if (!mounted) return;
    final exercises = results[1] as List<PlanExercise>;
    for (final e in exercises) {
      _weightControllers[e.id] = TextEditingController();
      _repsControllers[e.id] = TextEditingController();
      _logged[e.id] = [];
    }
    final profile = results[2] as AppUser?;
    setState(() {
      _sessionId = results[0] as String;
      _exercises = exercises;
      _restSeconds = profile?.defaultRestSeconds ?? 90;
      _loading = false;
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() => _restRemaining = _restSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 1) {
        t.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  Future<void> _logSet(PlanExercise exercise) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final weight = double.tryParse(_weightControllers[exercise.id]!.text.trim());
    final reps = int.tryParse(_repsControllers[exercise.id]!.text.trim());
    if (weight == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Enter both weight and reps.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final setIndex = _logged[exercise.id]!.length + 1;
    await WorkoutSessionRepository.instance.logSet(
      sessionId: sessionId,
      exerciseId: exercise.exerciseId,
      setIndex: setIndex,
      weightKg: weight,
      reps: reps,
    );
    if (!mounted) return;
    setState(() {
      _logged[exercise.id]!.add(_LoggedEntry(weight: weight, reps: reps));
      _repsControllers[exercise.id]!.clear();
    });
    _startRestTimer();
  }

  Future<void> _finish() async {
    if (_sessionId != null) {
      await WorkoutSessionRepository.instance.endSession(_sessionId!);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: _finish),
                  Expanded(
                    child: Text(widget.dayLabel, style: AppTextStyles.h3, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_restRemaining > 0)
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Text('REST', style: AppTextStyles.caption.copyWith(color: AppColors.background)),
                    Text('${_restRemaining}s', style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 32)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                itemCount: _exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, i) {
                  final e = _exercises[i];
                  final logged = _logged[e.id] ?? [];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.exerciseName ?? 'Exercise', style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        Text('${e.targetSets} sets × ${e.targetReps}', style: AppTextStyles.bodySmall),
                        if (logged.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          for (var s = 0; s < logged.length; s++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Set ${s + 1}: ${logged[s].weight} kg × ${logged[s].reps}',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightControllers[e.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(hintText: 'kg'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _repsControllers[e.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: 'reps'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: AppColors.primary,
                              child: InkWell(
                                onTap: () => _logSet(e),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Icon(Icons.check_rounded, color: AppColors.background),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PrimaryButton(label: 'Finish Workout', icon: Icons.check_circle_outline_rounded, onPressed: _finish),
            ),
          ],
        ),
      ),
    );
  }
}
