import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_user.dart';

/// Reads and writes profile rows (`public.profiles`). Rows are created by a
/// database trigger when an auth user is created (see supabase/migrations/).
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  SupabaseQueryBuilder get _profiles => Supabase.instance.client.from('profiles');

  Future<AppUser?> getUserProfile(String uid) async {
    final row = await _profiles.select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }

  // Home, Profile and Progress watch the same uid, and each StreamBuilder
  // re-reads this on every rebuild. Opening a fresh realtime subscription each
  // time reset screens to their "Athlete" fallback until the first snapshot
  // arrived. Caching one subscription per uid and replaying its last value
  // fixes both.
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

  /// Updates just the current weight -- Home's "Log Weight" quick action.
  Future<void> updateCurrentWeight({required String uid, required double weightKg}) {
    return _profiles.update({'current_weight_kg': weightKg}).eq('id', uid);
  }

  /// Updates just the goal fields -- the "Goals & Targets" screen.
  Future<void> updateGoal({
    required String uid,
    required FitnessGoal goal,
    required double targetWeightKg,
    required int goalDurationWeeks,
  }) {
    return _profiles.update({
      'goal': goal.storageValue,
      'target_weight_kg': targetWeightKg,
      'goal_duration_weeks': goalDurationWeeks,
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
    required int trainingDaysPerWeek,
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
      'training_days_per_week': trainingDaysPerWeek,
      'survey_completed': true,
    }).eq('id', uid);
  }

  /// Updates the Me tab's preferences (units, appearance, rest timer,
  /// workout reminders).
  Future<void> updateSettings({
    required String uid,
    ThemePreference? themePreference,
    UnitPreference? unitPreference,
    int? defaultRestSeconds,
    bool? workoutRemindersEnabled,
  }) {
    final updates = <String, dynamic>{};
    if (themePreference != null) updates['theme_preference'] = themePreference.storageValue;
    if (unitPreference != null) updates['unit_preference'] = unitPreference.storageValue;
    if (defaultRestSeconds != null) updates['default_rest_seconds'] = defaultRestSeconds;
    if (workoutRemindersEnabled != null) updates['workout_reminders_enabled'] = workoutRemindersEnabled;
    if (updates.isEmpty) return Future.value();
    return _profiles.update(updates).eq('id', uid);
  }
}

/// One shared realtime subscription for a profile row, broadcast to every
/// screen watching it. The last value is replayed to new listeners.
/// Right after login the realtime snapshot can race ahead of the session's
/// auth context and return zero rows. The profile row always exists for a
/// signed-in user, so empty results are ignored everywhere, even once a value
/// is cached; otherwise a late empty result overwrites a correct name.
class _ProfileStream {
  _ProfileStream(this._profiles, this._uid) {
    _retrySeed();
    _profiles.stream(primaryKey: ['id']).eq('id', _uid).map(
      (rows) => rows.isEmpty ? null : AppUser.fromMap(rows.first),
    ).listen(
      _handle,
      // A realtime channel error (e.g. a transient reconnect failure) says nothing
      // about whether the cached profile is still right. Forwarding it made every
      // StreamBuilder drop to its null/"Athlete" fallback, so errors are swallowed.
      onError: (_, __) {},
    );
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

  // Stream.multi instead of an async* generator: a generator only starts on the
  // next microtask after listen(), so a listener subscribing at that moment
  // could miss the cached value. Stream.multi runs its setup synchronously.
  Stream<AppUser?> get stream => Stream.multi((controller) {
        if (_hasValue) controller.add(_lastValue);
        final sub = _controller.stream.listen(controller.add, onError: controller.addError);
        controller.onCancel = sub.cancel;
      });
}
