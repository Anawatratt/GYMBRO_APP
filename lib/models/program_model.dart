import 'package:flutter/material.dart';

class Program {
  final String id;
  final String name;
  final String description;
  final String level;
  final String split;
  final String daysPerWeek;
  // UI related fields (derived or default)
  final int calories;
  final int durationMin;
  final int exercisesCount;
  
  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.split,
    required this.daysPerWeek,
    this.calories = 300, 
    this.durationMin = 45,
    this.exercisesCount = 6,
  });

  factory Program.fromMap(Map<String, dynamic> data, String documentId) {
    return Program(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      level: data['level'] ?? 'beginner',
      split: data['split'] ?? 'full_body',
      daysPerWeek: data['days_per_week'] ?? '3',
      // Default values for now as they are not in Firestore
      calories: 350, 
      durationMin: 45,
      exercisesCount: 7,
    );
  }

  // Helper getters for UI
  IconData get icon {
    switch (split.toLowerCase()) {
      case 'upper_body': return Icons.accessibility_new;
      case 'lower_body': return Icons.directions_run;
      case 'push_pull_legs': return Icons.fitness_center;
      default: return Icons.fitness_center;
    }
  }

  Color get color {
    switch (level.toLowerCase()) {
      case 'beginner': return const Color(0xFFE53935); // Indigo
      case 'intermediate': return const Color(0xFF00897B); // Teal
      case 'advanced': return const Color(0xFFD81B60); // Pink
      default: return const Color(0xFFE53935);
    } 
  }
}
