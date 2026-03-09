import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/storage_image.dart';

/// เรียกใช้: showExerciseDetailSheet(context, exerciseId, sets, reps, weight, restSec)
void showExerciseDetailSheet(
  BuildContext context, {
  required String exerciseId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExerciseDetailSheet(exerciseId: exerciseId),
  );
}

class _ExerciseDetailSheet extends StatelessWidget {
  final String exerciseId;

  const _ExerciseDetailSheet({required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('exercises')
                .doc(exerciseId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final name = data['exercise_name'] as String? ??
                  _formatSnakeCase(exerciseId);
              final description = data['description'] as String? ?? '';
              final movementPattern = data['movement_pattern'] as String? ?? '';
              final difficulty = data['difficulty_level'] as String? ?? '';
              final isCompound = data['is_compound'] as bool? ?? false;
              final muscles = List<Map<String, dynamic>>.from(
                  (data['muscle_involvements'] ?? [])
                      .map((e) => Map<String, dynamic>.from(e)));
              final equipment = List<Map<String, dynamic>>.from(
                  (data['equipment'] ?? [])
                      .map((e) => Map<String, dynamic>.from(e)));

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Exercise image
                  StorageImage(
                    storagePath: exerciseImagePath(exerciseId),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    placeholder: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withAlpha(12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.fitness_center,
                          size: 48, color: Color(0xFFE53935)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Color(0xFFE53935), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (difficulty.isNotEmpty)
                                  _Chip(
                                    label: _capitalize(difficulty),
                                    color: _difficultyColor(difficulty),
                                  ),
                                _Chip(
                                  label: isCompound ? 'Compound' : 'Isolation',
                                  color: const Color(0xFFE53935),
                                ),
                                if (movementPattern.isNotEmpty)
                                  _Chip(
                                    label: _capitalize(movementPattern),
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (description.isNotEmpty) ...[
                    _SectionTitle('Description'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Text(
                        description,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Muscles
                  if (muscles.isNotEmpty) ...[
                    _SectionTitle('Muscles Worked'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Column(
                        children: muscles.map((m) {
                          final muscleName =
                              m['muscle_name'] as String? ?? '';
                          final involvement =
                              m['involvement_type'] as String? ?? '';
                          final pct =
                              (m['activation_percentage'] as num?)?.toInt() ??
                                  0;
                          final isPrimary = involvement == 'primary';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isPrimary
                                        ? const Color(0xFFE53935)
                                        : Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    muscleName,
                                    style: TextStyle(
                                      fontWeight: isPrimary
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isPrimary
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                      color: isPrimary
                                          ? const Color(0xFFE53935)
                                          : Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: isPrimary
                                        ? const Color(0xFFE53935)
                                        : Colors.grey[400],
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Equipment
                  if (equipment.isNotEmpty) ...[
                    _SectionTitle('Equipment'),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Column(
                        children: equipment.map((eq) {
                          final eqName =
                              eq['equipment_name'] as String? ?? '';
                          final isRequired =
                              eq['is_required'] as bool? ?? false;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  isRequired
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isRequired
                                      ? const Color(0xFFE53935)
                                      : Colors.grey[400],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    eqName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isRequired
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                if (isRequired)
                                  Text(
                                    'Required',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400]),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatSnakeCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  String _capitalize(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Color _difficultyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF888888);
      case 'intermediate':
        return const Color(0xFF444444);
      case 'advanced':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
