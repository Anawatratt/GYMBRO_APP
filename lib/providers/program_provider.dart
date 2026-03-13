import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import 'auth_provider.dart';

export '../services/program_service.dart' show TodayWorkout, TodayExercise;

final programServiceProvider =
    Provider<ProgramService>((ref) => ProgramService());

/// Stream of all programs from Firestore.
final programsStreamProvider = StreamProvider<List<Program>>((ref) {
  return ref.watch(programServiceProvider).getPrograms();
});

/// Today's workout for the current user's active program.
final todayWorkoutProvider =
    FutureProvider.autoDispose<TodayWorkout?>((ref) async {
  final appUser = ref.watch(currentUserDocProvider).value;
  final programId = appUser?.activeProgramId;
  if (programId == null || programId.isEmpty) return null;
  return ref.read(programServiceProvider).getTodayWorkout(programId);
});
