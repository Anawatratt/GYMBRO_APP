import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(uid, snap.data()!);
    });
  }

  Future<AppUser?> getUserOnce(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  Future<void> completeProfile({
    required String uid,
    required String displayName,
    required String fitnessLevel,
    String bio = '',
    String gymName = 'CMU Gym',
  }) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName.trim(),
      'fitnessLevel': fitnessLevel,
      'bio': bio.trim(),
      'gymName': gymName.trim().isEmpty ? 'CMU Gym' : gymName.trim(),
      'profileComplete': true,
    });
  }
}
