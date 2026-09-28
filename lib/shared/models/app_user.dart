enum FitnessGoal { gainWeight, loseWeight, stayFit }

extension FitnessGoalLabel on FitnessGoal {
  String get label => switch (this) {
        FitnessGoal.gainWeight => 'Gain Weight',
        FitnessGoal.loseWeight => 'Lose Weight',
        FitnessGoal.stayFit => 'Stay Fit',
      };

  String get storageValue => name;

  static FitnessGoal? fromStorage(String? value) {
    for (final goal in FitnessGoal.values) {
      if (goal.storageValue == value) return goal;
    }
    return null;
  }
}

enum ThemePreference { light, dark, system }

extension ThemePreferenceX on ThemePreference {
  String get storageValue => name;

  static ThemePreference fromStorage(String? value) {
    for (final pref in ThemePreference.values) {
      if (pref.storageValue == value) return pref;
    }
    return ThemePreference.system;
  }
}

enum UnitPreference { kg, lb }

extension UnitPreferenceX on UnitPreference {
  String get storageValue => name;

  static UnitPreference fromStorage(String? value) {
    for (final pref in UnitPreference.values) {
      if (pref.storageValue == value) return pref;
    }
    return UnitPreference.kg;
  }
}

/// A user's profile row, stored in Supabase Postgres at `public.profiles`
/// (one row per `auth.users` row, primary key `id`).
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    this.goal,
    this.targetWeightKg,
    this.goalDurationWeeks,
    this.surveyCompleted = false,
    this.trainingDaysPerWeek,
    this.themePreference = ThemePreference.system,
    this.unitPreference = UnitPreference.kg,
    this.defaultRestSeconds = 90,
    this.workoutRemindersEnabled = false,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  /// Fields collected by the onboarding survey (null until completed).
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final FitnessGoal? goal;
  final double? targetWeightKg;
  final int? goalDurationWeeks;
  final bool surveyCompleted;
  final int? trainingDaysPerWeek;

  /// Settings from the Me tab.
  final ThemePreference themePreference;
  final UnitPreference unitPreference;
  final int defaultRestSeconds;
  final bool workoutRemindersEnabled;

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['id'] as String,
        email: map['email'] as String? ?? '',
        displayName: (map['display_name'] as String?) ?? 'Athlete',
        photoUrl: map['photo_url'] as String?,
        createdAt: map['created_at'] == null ? DateTime.now() : DateTime.parse(map['created_at'] as String),
        age: map['age'] as int?,
        gender: map['gender'] as String?,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        currentWeightKg: (map['current_weight_kg'] as num?)?.toDouble(),
        goal: FitnessGoalLabel.fromStorage(map['goal'] as String?),
        targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
        goalDurationWeeks: map['goal_duration_weeks'] as int?,
        surveyCompleted: map['survey_completed'] as bool? ?? false,
        trainingDaysPerWeek: map['training_days_per_week'] as int?,
        themePreference: ThemePreferenceX.fromStorage(map['theme_preference'] as String?),
        unitPreference: UnitPreferenceX.fromStorage(map['unit_preference'] as String?),
        defaultRestSeconds: map['default_rest_seconds'] as int? ?? 90,
        workoutRemindersEnabled: map['workout_reminders_enabled'] as bool? ?? false,
      );
}
