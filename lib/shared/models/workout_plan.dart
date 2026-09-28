enum PlanSource { ai, custom, import }

extension PlanSourceX on PlanSource {
  String get storageValue => name;

  static PlanSource fromStorage(String? value) {
    for (final source in PlanSource.values) {
      if (source.storageValue == value) return source;
    }
    return PlanSource.custom;
  }
}

/// A saved training plan (`public.workout_plans`).
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.source,
    required this.daysPerWeek,
    this.durationWeeks,
    this.level,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final PlanSource source;
  final int daysPerWeek;
  final int? durationWeeks;
  final String? level;
  final bool isActive;
  final DateTime createdAt;

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) => WorkoutPlan(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        source: PlanSourceX.fromStorage(map['source'] as String?),
        daysPerWeek: map['days_per_week'] as int,
        durationWeeks: map['duration_weeks'] as int?,
        level: map['level'] as String?,
        isActive: map['is_active'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// One training day within a plan (`public.plan_days`).
class PlanDay {
  const PlanDay({
    required this.id,
    required this.planId,
    required this.dayIndex,
    required this.label,
  });

  final String id;
  final String planId;
  final int dayIndex;
  final String label;

  factory PlanDay.fromMap(Map<String, dynamic> map) => PlanDay(
        id: map['id'] as String,
        planId: map['plan_id'] as String,
        dayIndex: map['day_index'] as int,
        label: map['label'] as String,
      );
}

/// One exercise prescribed on a plan day (`public.plan_exercises`).
class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.planDayId,
    required this.exerciseId,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    this.notes,
    this.exerciseName,
  });

  final String id;
  final String planDayId;
  final String exerciseId;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final String? notes;

  /// Populated when joined against `exercises` so callers don't need a
  /// second lookup just to show the exercise's name.
  final String? exerciseName;

  factory PlanExercise.fromMap(Map<String, dynamic> map) => PlanExercise(
        id: map['id'] as String,
        planDayId: map['plan_day_id'] as String,
        exerciseId: map['exercise_id'] as String,
        orderIndex: map['order_index'] as int? ?? 0,
        targetSets: map['target_sets'] as int,
        targetReps: map['target_reps'] as String,
        notes: map['notes'] as String?,
        exerciseName: (map['exercises'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
