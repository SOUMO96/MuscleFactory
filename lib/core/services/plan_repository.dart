import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/workout_plan.dart';

/// Reads and writes a user's training plans (`public.workout_plans` +
/// `plan_days` + `plan_exercises`).
class PlanRepository {
  PlanRepository._();
  static final PlanRepository instance = PlanRepository._();

  SupabaseQueryBuilder get _plans => Supabase.instance.client.from('workout_plans');
  SupabaseQueryBuilder get _planDays => Supabase.instance.client.from('plan_days');
  SupabaseQueryBuilder get _planExercises => Supabase.instance.client.from('plan_exercises');

  Future<WorkoutPlan?> getActivePlan(String userId) async {
    final row = await _plans.select().eq('user_id', userId).eq('is_active', true).order('created_at', ascending: false).limit(1).maybeSingle();
    if (row == null) return null;
    return WorkoutPlan.fromMap(row);
  }

  Future<List<PlanDay>> getPlanDays(String planId) async {
    // postgrest's .order() is descending by default; without ascending: true the
    // days come back reversed, which also breaks Home's day rotation.
    final rows = await _planDays.select().eq('plan_id', planId).order('day_index', ascending: true);
    return rows.map(PlanDay.fromMap).toList();
  }

  Future<List<PlanExercise>> getPlanExercises(String planDayId) async {
    final rows = await _planExercises.select('*, exercises(name)').eq('plan_day_id', planDayId).order('order_index', ascending: true);
    return rows.map(PlanExercise.fromMap).toList();
  }

  /// Creates a new plan and deactivates any previously active plan for the
  /// user (best-effort -- PostgREST has no client-side multi-table
  /// transaction, so this is two calls, not one atomic statement).
  Future<String> createPlan({
    required String userId,
    required String name,
    required PlanSource source,
    required int daysPerWeek,
    int? durationWeeks,
    String? level,
  }) async {
    await _plans.update({'is_active': false}).eq('user_id', userId).eq('is_active', true);
    final row = await _plans
        .insert({
          'user_id': userId,
          'name': name,
          'source': source.storageValue,
          'days_per_week': daysPerWeek,
          'duration_weeks': durationWeeks,
          'level': level,
          'is_active': true,
        })
        .select()
        .single();
    return row['id'] as String;
  }

  /// Days and exercises cascade-delete with the plan; logged workout
  /// sessions are kept (their plan_day_id is set null), so history survives.
  Future<void> deletePlan(String planId) => _plans.delete().eq('id', planId);

  Future<String> addPlanDay({required String planId, required int dayIndex, required String label}) async {
    final row = await _planDays.insert({'plan_id': planId, 'day_index': dayIndex, 'label': label}).select().single();
    return row['id'] as String;
  }

  Future<void> addPlanExercise({
    required String planDayId,
    required String exerciseId,
    required int orderIndex,
    required int targetSets,
    required String targetReps,
    String? notes,
  }) {
    return _planExercises.insert({
      'plan_day_id': planDayId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'notes': notes,
    });
  }
}
