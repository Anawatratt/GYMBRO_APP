import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/note_service.dart';
import '../models/note.dart';
import 'auth_provider.dart';

final noteServiceProvider = Provider<NoteService>((ref) => NoteService());

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(noteServiceProvider).notesStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// View another user's notes (read-only)
final notesByUidProvider = StreamProvider.autoDispose
    .family<List<Note>, String>((ref, uid) {
      return ref.watch(noteServiceProvider).notesStream(uid);
    });
