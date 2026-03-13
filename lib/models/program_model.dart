import 'package:flutter/material.dart';

class Program {
  final String id;
  final String programName;
  final String description;
  final String goal;
  final String difficultyLevel;
  final int daysPerWeek;
  final int durationWeeks;

  const Program({
    required this.id,
    required this.programName,
    required this.description,
    required this.goal,
    required this.difficultyLevel,
    required this.daysPerWeek,
    required this.durationWeeks,
  });

  factory Program.fromMap(Map<String, dynamic> data, String documentId) {
    return Program(
      id: documentId,
      programName: data['program_name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      difficultyLevel: data['difficulty_level'] as String? ?? '',
      daysPerWeek: (data['days_per_week'] as num?)?.toInt() ?? 0,
      durationWeeks: (data['duration_weeks'] as num?)?.toInt() ?? 0,
    );
  }

  IconData get goalIcon {
    switch (goal) {
      case 'muscle_gain':
        return Icons.fitness_center;
      case 'strength':
        return Icons.bolt;
      case 'general_fitness':
        return Icons.directions_run;
      default:
        return Icons.sports_gymnastics;
    }
  }
}
