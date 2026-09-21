import 'dart:async';

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

  // Home, Profile and Progress all watch the same uid independently, and
  // each StreamBuilder re-reads this every rebuild (e.g. when the browser
  // tab regains focus). Calling `.stream()` fresh each time tore down and
  // re-opened a new Supabase realtime subscription every rebuild, which
  // briefly reset each screen to its no-data fallback ("Athlete") until
  // the new subscription's first snapshot arrived -- and would stay stuck
  // there if that round-trip didn't complete. Caching one subscription
  // per uid and replaying its last value to every new listener fixes
  // both the redundant resubscribing and the fallback flicker.
  final Map<String, _ProfileStream> _profileStreams = {};

  Stream<AppUser?> watchUserProfile(String uid) {
    return _profileStreams.putIfAbsent(uid, () => _ProfileStream(_profiles, uid)).stream;
  }

  /// Reports whether [uid] has completed the onboarding survey. The
  /// profile row itself always exists by the time this is called (created
  /// by the database trigger as part of sign-up), so this is just a read.
  Future<bool> ensureProfile(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.surveyCompleted ?? false;
  }

  /// Updates the editable personal-info fields from the Profile ->
  /// Personal Information screen, without touching goal/target fields.
  Future<void> updatePersonalInfo({
    required String uid,
    required String name,
    required int age,
    required String gender,
    required double heightCm,
    required double currentWeightKg,
  }) {
    return _profiles.update({
      'display_name': name,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
    }).eq('id', uid);
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

/// One shared Supabase realtime subscription for a given profile row,
/// broadcast to however many screens are currently watching it. Replays
/// the last known value to each new listener so a screen that starts
/// watching after the initial snapshot already arrived (e.g. navigating
/// to a different tab) isn't left waiting for the next database change.
///
/// Right after a fresh login, the realtime subscription's own initial
/// snapshot has been observed to occasionally race ahead of the new
/// session's auth context and come back with zero rows. The profile row
/// always exists once a user is signed in (a database trigger creates
/// it at sign-up), so an empty/null result is never trustworthy: it is
/// always ignored rather than cached or broadcast, from either the
/// retry-seed below or the realtime listener. This matters even after a
/// real value has already loaded, because the two sources race
/// independently -- a slower, separately-racing empty result from the
/// realtime side has been observed to land *after* the retry-seed
/// already succeeded, which (when null was allowed through once a value
/// existed) clobbered a correct name back to placeholder copy
/// ("Athlete") a second or two after it briefly showed correctly.
class _ProfileStream {
  _ProfileStream(this._profiles, this._uid) {
    _retrySeed();
    _profiles.stream(primaryKey: ['id']).eq('id', _uid).map(
      (rows) => rows.isEmpty ? null : AppUser.fromMap(rows.first),
    ).listen(_handle, onError: _controller.addError);
  }

  final SupabaseQueryBuilder _profiles;
  final String _uid;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _lastValue;
  bool _hasValue = false;

  void _handle(AppUser? value) {
    if (value == null) return;
    _hasValue = true;
    _lastValue = value;
    _controller.add(value);
  }

  Future<void> _retrySeed() async {
    for (var attempt = 0; attempt < 6 && !_hasValue; attempt++) {
      if (attempt > 0) await Future.delayed(const Duration(milliseconds: 400));
      try {
        final row = await _profiles.select().eq('id', _uid).maybeSingle();
        if (row != null) {
          _handle(AppUser.fromMap(row));
          return;
        }
      } catch (_) {
        // Keep retrying -- the realtime listener may also resolve this
        // independently in the meantime.
      }
    }
  }

  Stream<AppUser?> get stream async* {
    if (_hasValue) yield _lastValue;
    yield* _controller.stream;
  }
}
