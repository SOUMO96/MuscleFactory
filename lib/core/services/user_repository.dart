import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_user.dart';

/// Reads and writes profile rows in Supabase Postgres (`public.profiles`).
///
/// Row creation itself is handled automatically by a database trigger
/// (see supabase/migrations/) whenever a new auth user is created, for
/// both email/password sign-up and Google sign-in alike.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  SupabaseQueryBuilder get _profiles => Supabase.instance.client.from('profiles');

  Future<AppUser?> getUserProfile(String uid) async {
    final row = await _profiles.select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    return _profiles.stream(primaryKey: ['id']).eq('id', uid).map(
          (rows) => rows.isEmpty ? null : AppUser.fromMap(rows.first),
        );
  }

  /// Reports whether [uid] has completed the onboarding survey. The
  /// profile row itself always exists by the time this is called (created
  /// by the database trigger as part of sign-up), so this is just a read.
  Future<bool> ensureProfile(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.surveyCompleted ?? false;
  }

  Future<void> saveSurveyResults({
    required String uid,
    required String name,
    required int age,
    required String gender,
    required double heightCm,
    required double currentWeightKg,
    required FitnessGoal goal,
    required double targetWeightKg,
    required int goalDurationWeeks,
  }) {
    return _profiles.update({
      'display_name': name,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'goal': goal.storageValue,
      'target_weight_kg': targetWeightKg,
      'goal_duration_weeks': goalDurationWeeks,
      'survey_completed': true,
    }).eq('id', uid);
  }
}
