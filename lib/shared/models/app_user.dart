import 'package:cloud_firestore/cloud_firestore.dart';

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

/// A user's profile document stored in Firestore at `users/{uid}`.
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

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'goal': goal?.storageValue,
        'targetWeightKg': targetWeightKg,
        'goalDurationWeeks': goalDurationWeeks,
        'surveyCompleted': surveyCompleted,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: (map['displayName'] as String?) ?? 'Athlete',
        photoUrl: map['photoUrl'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        age: map['age'] as int?,
        gender: map['gender'] as String?,
        heightCm: (map['heightCm'] as num?)?.toDouble(),
        currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble(),
        goal: FitnessGoalLabel.fromStorage(map['goal'] as String?),
        targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble(),
        goalDurationWeeks: map['goalDurationWeeks'] as int?,
        surveyCompleted: map['surveyCompleted'] as bool? ?? false,
      );
}
