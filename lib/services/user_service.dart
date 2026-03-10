import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images/$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    await _db.collection('users').doc(uid).update({
      'image_url': imageUrl,
      'photoUrl': imageUrl,
    });
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
      'name': displayName.trim(), // keep legacy UserProfile field in sync
      'fitnessLevel': fitnessLevel,
      'bio': bio.trim(),
      'gymName': gymName.trim().isEmpty ? 'CMU Gym' : gymName.trim(),
      'profileComplete': true,
    });
  }
}
