/// A single training session (`public.workout_sessions`).
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    this.planDayId,
    required this.startedAt,
    this.endedAt,
    this.planDayLabel,
  });

  final String id;
  final String userId;
  final String? planDayId;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Populated when joined against `plan_days` for display purposes.
  final String? planDayLabel;

  bool get isFinished => endedAt != null;

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        planDayId: map['plan_day_id'] as String?,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: map['ended_at'] == null ? null : DateTime.parse(map['ended_at'] as String),
        planDayLabel: (map['plan_days'] as Map<String, dynamic>?)?['label'] as String?,
      );
}

/// One completed set within a session (`public.logged_sets`).
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    this.weightKg,
    this.reps,
    required this.completedAt,
    this.exerciseName,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final double? weightKg;
  final int? reps;
  final DateTime completedAt;
  final String? exerciseName;

  factory LoggedSet.fromMap(Map<String, dynamic> map) => LoggedSet(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        exerciseId: map['exercise_id'] as String,
        setIndex: map['set_index'] as int,
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        reps: map['reps'] as int?,
        completedAt: DateTime.parse(map['completed_at'] as String),
        exerciseName: (map['exercises'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
