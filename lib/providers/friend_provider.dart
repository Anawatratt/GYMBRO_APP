import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/friend_service.dart';
import '../models/friend.dart';
import 'auth_provider.dart';

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

final friendsStreamProvider = StreamProvider<List<Friend>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(friendServiceProvider).friendsStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
