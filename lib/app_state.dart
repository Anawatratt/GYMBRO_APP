import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data.dart';

// ── UserProfile model ────────────────────────────────────

class UserProfile {
  final String uid;
  final String username;
  final String name;
  final String? imageUrl;
  final List<String> friends;
  final String? activeProgramId;

  const UserProfile({
    required this.uid,
    required this.username,
    required this.name,
    this.imageUrl,
    this.friends = const [],
    this.activeProgramId,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      username: data['username'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['image_url'] as String?,
      friends: List<String>.from(data['friends'] ?? []),
      activeProgramId: data['active_program_id'] as String?,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

// ── Auth stream providers ────────────────────────────────

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) =>
              doc.exists ? UserProfile.fromMap(doc.id, doc.data()!) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Provider for any user's profile (for friend viewing)
final profileByUidProvider =
    StreamProvider.autoDispose.family<UserProfile?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) =>
          doc.exists ? UserProfile.fromMap(doc.id, doc.data()!) : null);
});

// ── Auth actions ─────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: '${username.trim()}@gymbro.internal',
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String name,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: '${username.trim()}@gymbro.internal',
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'username': username.trim(),
        'name': name.trim(),
        'image_url': imageUrl,
        'friends': [],
        'active_program_id': null,
        'created_at': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Returns null on success, error message on failure
  Future<String?> addFriend(String friendUsername) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'Not logged in';

    final q = await _db
        .collection('users')
        .where('username', isEqualTo: friendUsername.trim())
        .limit(1)
        .get();

    if (q.docs.isEmpty) return 'User not found';
    final friendUid = q.docs.first.id;
    if (friendUid == currentUser.uid) return 'Cannot add yourself';

    await _db.collection('users').doc(currentUser.uid).update({
      'friends': FieldValue.arrayUnion([friendUid]),
    });
    return null;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

// ── Active program helper ─────────────────────────────────

Future<void> setActiveProgram(String? programId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({'active_program_id': programId});
}

// ── Notes — Firestore-backed ──────────────────────────────

Note _noteFromDoc(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Note(
    id: doc.id,
    title: data['title'] as String? ?? '',
    body: data['body'] as String? ?? '',
    color: Color(data['color'] as int? ?? 0xFFFFF9C4),
    createdAt:
        (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// Stream of notes for any uid (view-only for friends)
final notesProvider =
    StreamProvider.autoDispose.family<List<Note>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('notes')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_noteFromDoc).toList());
});

Future<void> addNoteFs(String uid, Note note) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(note.id)
        .set({
      'title': note.title,
      'body': note.body,
      'color': note.color.value,
      'created_at': FieldValue.serverTimestamp(),
    });

Future<void> updateNoteFs(String uid, String noteId,
        {String? title, String? body, Color? color}) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'title': ?title,
      'body': ?body,
      if (color != null) 'color': color.value,
    });

Future<void> deleteNoteFs(String uid, String noteId) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .delete();
