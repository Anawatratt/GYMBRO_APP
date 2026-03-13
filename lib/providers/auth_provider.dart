import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Stream of Firebase Auth user (null = not logged in).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Stream of the current user's Firestore document.
final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Stream of any user's Firestore document by UID.
final userByUidProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(userServiceProvider).userStream(uid);
});
