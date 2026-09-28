import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/workout_session.dart';

/// Reads and writes workout sessions and the sets logged within them
/// (`public.workout_sessions` + `public.logged_sets`) -- backs the Active
/// Workout set logger, workout history, and Progress's real stats.
class WorkoutSessionRepository {
  WorkoutSessionRepository._();
  static final WorkoutSessionRepository instance = WorkoutSessionRepository._();

  SupabaseQueryBuilder get _sessions => Supabase.instance.client.from('workout_sessions');
  SupabaseQueryBuilder get _sets => Supabase.instance.client.from('logged_sets');

  Future<String> startSession({required String userId, String? planDayId}) async {
    final row = await _sessions.insert({'user_id': userId, 'plan_day_id': planDayId}).select().single();
    return row['id'] as String;
  }

  Future<void> endSession(String sessionId) {
    return _sessions.update({'ended_at': DateTime.now().toUtc().toIso8601String()}).eq('id', sessionId);
  }

  Future<void> logSet({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
    double? weightKg,
    int? reps,
  }) {
    return _sets.insert({
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_index': setIndex,
      'weight_kg': weightKg,
      'reps': reps,
    });
  }

  Future<List<WorkoutSession>> history(String userId, {int limit = 30}) async {
    final rows = await _sessions
        .select('*, plan_days(label)')
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<LoggedSet>> setsForSession(String sessionId) async {
    final rows = await _sets.select('*, exercises(name)').eq('session_id', sessionId).order('set_index');
    return rows.map(LoggedSet.fromMap).toList();
  }

  /// All sets logged by [userId] since [since] (defaults to 90 days back),
  /// joined with exercise names -- the raw data Progress aggregates client
  /// side into volume-over-time and personal records.
  Future<List<LoggedSet>> recentSets(String userId, {DateTime? since}) async {
    final cutoff = (since ?? DateTime.now().subtract(const Duration(days: 90))).toUtc().toIso8601String();
    final rows = await Supabase.instance.client
        .from('logged_sets')
        .select('*, exercises(name), workout_sessions!inner(user_id)')
        .eq('workout_sessions.user_id', userId)
        .gte('completed_at', cutoff)
        .order('completed_at');
    return rows.map((r) => LoggedSet.fromMap(r)).toList();
  }
}
