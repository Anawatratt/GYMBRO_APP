import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program_model.dart';

class TodayExercise {
  final String exerciseId;
  final int sets;
  final int reps;
  final double? weight;
  const TodayExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
  });
}

class TodayWorkout {
  final String programName;
  final String sessionName;
  final String programId;
  final List<TodayExercise> exercises;
  const TodayWorkout({
    required this.programName,
    required this.sessionName,
    required this.programId,
    this.exercises = const [],
  });
}

class ProgramService {
  final CollectionReference _programsCollection =
      FirebaseFirestore.instance.collection('programs');

  Stream<List<Program>> getPrograms() {
    return _programsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Program.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<TodayWorkout?> getTodayWorkout(String programId) async {
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun

    final programDoc = await _programsCollection.doc(programId).get();
    if (!programDoc.exists) return null;
    final programName =
        (programDoc.data() as Map<String, dynamic>?)?['program_name']
                as String? ??
            '';

    final sessionsSnap = await _programsCollection
        .doc(programId)
        .collection('sessions')
        .where('day_number', isEqualTo: today)
        .limit(1)
        .get();

    if (sessionsSnap.docs.isEmpty) {
      return TodayWorkout(
        programName: programName,
        sessionName: 'Rest Day',
        programId: programId,
      );
    }

    final sessionData = sessionsSnap.docs.first.data();
    final sessionName = sessionData['session_name'] as String? ?? '';
    final rawExercises = (sessionData['exercises'] as List<dynamic>? ?? []);
    rawExercises.sort((a, b) =>
        (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

    final exercises = rawExercises.map((e) {
      final map = e as Map<String, dynamic>;
      return TodayExercise(
        exerciseId: map['exercise_id'] as String? ?? '',
        sets: (map['sets'] as num?)?.toInt() ?? 0,
        reps: (map['reps'] as num?)?.toInt() ?? 0,
        weight: (map['weight'] as num?)?.toDouble(),
      );
    }).toList();

    return TodayWorkout(
      programName: programName,
      sessionName: sessionName,
      programId: programId,
      exercises: exercises,
    );
  }
}
