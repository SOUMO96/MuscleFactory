import 'package:cloud_firestore/cloud_firestore.dart';

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
}
