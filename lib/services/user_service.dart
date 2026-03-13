import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Storage path is always `profile_images/{uid}.jpg` — permanently UID-linked.
  static String profileImagePath(String uid) => 'profile_images/$uid.jpg';

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
    final ref = FirebaseStorage.instance.ref().child(profileImagePath(uid));
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Saves the download URL and storage path to Firestore.
  /// Both `image_url` and `photoUrl` are kept in sync.
  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    await _db.collection('users').doc(uid).update({
      'image_url': imageUrl,
      'photoUrl': imageUrl,
      'profileImagePath': profileImagePath(uid),
    });
  }

  /// Always fetches a fresh download URL from Firebase Storage using the
  /// stored path, then saves it back to Firestore.
  /// Call this on login so the URL is always valid even if the token expired.
  Future<void> refreshProfileImageUrl(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) return;

      // Use stored path or fall back to the conventional UID-based path.
      final path = snap.data()?['profileImagePath'] as String? ??
          profileImagePath(uid);
      final freshUrl =
          await FirebaseStorage.instance.ref().child(path).getDownloadURL();

      await _db.collection('users').doc(uid).update({
        'image_url': freshUrl,
        'photoUrl': freshUrl,
        'profileImagePath': path,
      });
    } catch (_) {
      // No image in Storage yet — nothing to refresh.
    }
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
