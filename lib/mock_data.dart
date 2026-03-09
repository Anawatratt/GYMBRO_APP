import 'package:flutter/material.dart';

// ── Models ──────────────────────────────────────────────

class Exercise {
  final String name;
  final String muscle;
  final String difficulty;
  final String sets;

  const Exercise({
    required this.name,
    required this.muscle,
    required this.difficulty,
    this.sets = '3 x 10',
  });
}

class Plan {
  final String title;
  final IconData icon;
  final Color color;
  final int calories;
  final int durationMin;
  final int exercisesCount;

  const Plan({
    required this.title,
    required this.icon,
    required this.color,
    required this.calories,
    required this.durationMin,
    required this.exercisesCount,
  });
}

class Trainee {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final int workoutsCompleted;
  final int totalSets;
  final int totalReps;
  final Map<String, double> muscleProgress;

  const Trainee({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.workoutsCompleted = 0,
    this.totalSets = 0,
    this.totalReps = 0,
    this.muscleProgress = const {},
  });
}

class Note {
  final String id;
  final String title;
  final String body;
  final Color color;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    required this.createdAt,
  });

  Note copyWith({String? title, String? body, Color? color}) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}

const noteColors = [
  Color(0xFFFFF9C4), // yellow
  Color(0xFFB3E5FC), // light blue
  Color(0xFFC8E6C9), // light green
  Color(0xFFF8BBD0), // pink
  Color(0xFFFFE0B2), // orange
];

final List<Exercise> mockExercises = [
  Exercise(name: 'Bench Press', muscle: 'Chest', difficulty: 'Intermediate', sets: '4 x 8'),
  Exercise(name: 'Push Ups', muscle: 'Chest', difficulty: 'Beginner', sets: '3 x 15'),
  Exercise(name: 'Dumbbell Rows', muscle: 'Back', difficulty: 'Intermediate', sets: '3 x 12'),
  Exercise(name: 'Squats', muscle: 'Legs', difficulty: 'Beginner', sets: '4 x 10'),
  Exercise(name: 'Lunges', muscle: 'Legs', difficulty: 'Intermediate', sets: '3 x 12'),
  Exercise(name: 'Plank', muscle: 'Core', difficulty: 'Beginner', sets: '3 x 60s'),
  Exercise(name: 'Pull Ups', muscle: 'Back', difficulty: 'Advanced', sets: '4 x 8'),
  Exercise(name: 'Deadlift', muscle: 'Back', difficulty: 'Advanced', sets: '4 x 6'),
  Exercise(name: 'Shoulder Press', muscle: 'Shoulders', difficulty: 'Intermediate', sets: '3 x 10'),
  Exercise(name: 'Bicep Curls', muscle: 'Arms', difficulty: 'Beginner', sets: '3 x 12'),
];

final List<Plan> mockPlans = [
  Plan(
    title: 'Full Body',
    icon: Icons.fitness_center,
    color: const Color(0xFFE53935),
    calories: 450,
    durationMin: 45,
    exercisesCount: 8,
  ),
  Plan(
    title: 'Upper Body',
    icon: Icons.accessibility_new,
    color: const Color(0xFF00897B),
    calories: 350,
    durationMin: 40,
    exercisesCount: 7,
  ),
  Plan(
    title: 'Lower Body',
    icon: Icons.directions_run,
    color: const Color(0xFFFF7043),
    calories: 400,
    durationMin: 40,
    exercisesCount: 7,
  ),
];

// ── Trainee mock data ───────────────────────────────────

final List<Trainee> mockTrainees = [
  Trainee(
    id: 'jj',
    name: 'JJ',
    initials: 'JJ',
    avatarColor: const Color(0xFFE53935),
    workoutsCompleted: 3,
    totalSets: 1240,
    totalReps: 9510,
    muscleProgress: const {
      'Chest': 0.75, 'Back': 0.60, 'Legs': 0.85,
      'Arms': 0.48, 'Core': 0.72, 'Shoulders': 0.55,
      'Forearms': 0.35, 'Calves': 0.40,
    },
  ),
  Trainee(
    id: 'sarah',
    name: 'Sarah Johnson',
    initials: 'SJ',
    avatarColor: const Color(0xFF00897B),
    workoutsCompleted: 2,
    totalSets: 860,
    totalReps: 6200,
    muscleProgress: const {
      'Chest': 0.40, 'Back': 0.70, 'Legs': 0.90,
      'Arms': 0.35, 'Core': 0.80, 'Shoulders': 0.45,
      'Forearms': 0.25, 'Calves': 0.55,
    },
  ),
  Trainee(
    id: 'mike',
    name: 'Mike Chen',
    initials: 'MC',
    avatarColor: const Color(0xFFFF7043),
    workoutsCompleted: 4,
    totalSets: 1580,
    totalReps: 11200,
    muscleProgress: const {
      'Chest': 0.85, 'Back': 0.80, 'Legs': 0.50,
      'Arms': 0.70, 'Core': 0.55, 'Shoulders': 0.75,
      'Forearms': 0.45, 'Calves': 0.30,
    },
  ),
  Trainee(
    id: 'emily',
    name: 'Emily Davis',
    initials: 'ED',
    avatarColor: const Color(0xFF7E57C2),
    workoutsCompleted: 3,
    totalSets: 950,
    totalReps: 7100,
    muscleProgress: const {
      'Chest': 0.35, 'Back': 0.55, 'Legs': 0.95,
      'Arms': 0.30, 'Core': 0.88, 'Shoulders': 0.40,
      'Forearms': 0.20, 'Calves': 0.65,
    },
  ),
  Trainee(
    id: 'david',
    name: 'David Kim',
    initials: 'DK',
    avatarColor: const Color(0xFF26A69A),
    workoutsCompleted: 3,
    totalSets: 1100,
    totalReps: 8400,
    muscleProgress: const {
      'Chest': 0.65, 'Back': 0.75, 'Legs': 0.70,
      'Arms': 0.60, 'Core': 0.60, 'Shoulders': 0.65,
      'Forearms': 0.50, 'Calves': 0.45,
    },
  ),
];

// ── Notes mock data (per profile) ───────────────────────

final Map<String, List<Note>> mockNotesByProfile = {
  'jj': [
    Note(id: '1', title: 'Shoulder pain', body: 'Left shoulder tight after bench press. Reduce weight next session.', color: const Color(0xFFFFF9C4), createdAt: DateTime(2026, 2, 7)),
    Note(id: '2', title: 'Diet update', body: 'Increase protein to 150g/day. Add chicken meal prep.', color: const Color(0xFFB3E5FC), createdAt: DateTime(2026, 2, 5)),
  ],
  'sarah': [
    Note(id: '3', title: 'Great squat PR!', body: 'Hit 80kg squat today! Form looked solid on all reps.', color: const Color(0xFFC8E6C9), createdAt: DateTime(2026, 2, 8)),
    Note(id: '4', title: 'Flexibility', body: 'Need more hip stretches before leg day.', color: const Color(0xFFF8BBD0), createdAt: DateTime(2026, 2, 6)),
  ],
  'mike': [
    Note(id: '5', title: 'Bench goal', body: 'Target: 100kg bench by March. Current: 90kg.', color: const Color(0xFFFFE0B2), createdAt: DateTime(2026, 2, 7)),
  ],
  'emily': [],
  'david': [],
};
