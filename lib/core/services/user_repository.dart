import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/models/app_user.dart';

/// Reads and writes user profile documents in Firestore.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUserProfile(AppUser user) {
    return _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Stream<AppUser?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(data);
    });
  }

  /// Ensures a Firestore profile document exists for [user] (creating a
  /// bare-bones one from their Firebase Auth info if this is their first
  /// time), and reports whether they've already completed the onboarding
  /// survey. Call this right after any successful sign-in/sign-up to
  /// decide whether to route to the survey or straight into the app.
  Future<bool> ensureProfile(User user) async {
    final existing = await getUserProfile(user.uid);
    if (existing != null) return existing.surveyCompleted;

    await createUserProfile(
      AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: (user.displayName?.trim().isNotEmpty ?? false) ? user.displayName! : 'Athlete',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      ),
    );
    return false;
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
    return _users.doc(uid).set({
      'displayName': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'currentWeightKg': currentWeightKg,
      'goal': goal.storageValue,
      'targetWeightKg': targetWeightKg,
      'goalDurationWeeks': goalDurationWeeks,
      'surveyCompleted': true,
    }, SetOptions(merge: true));
  }
}
