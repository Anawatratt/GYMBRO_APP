import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workout_history')
            .where('user_id', isEqualTo: uid)
            .orderBy('completed_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No workout history yet',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Complete a session to see it here',
                      style:
                          TextStyle(color: Colors.grey[350], fontSize: 13)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _HistoryCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final programName = data['program_name'] ?? '';
    final sessionName = data['session_name'] ?? '';
    final exercises = data['exercises'] as List<dynamic>? ?? [];
    final completedAt = data['completed_at'];

    String dateStr = '';
    if (completedAt is Timestamp) {
      final dt = completedAt.toDate();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: const Color(0xFFE53935), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sessionName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(programName,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${exercises.length} exercises',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                  size: 22,
                ),
              ],
            ),

            // Expanded exercise list
            if (_expanded && exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...exercises.map((ex) {
                final exData = ex as Map<String, dynamic>;
                final exerciseId = exData['exercise_id'] as String? ?? '';
                final sets = exData['sets'] ?? 0;
                final reps = exData['reps'] ?? 0;
                final weight = exData['weight'];
                final weightStr = weight != null
                    ? '${(weight as num).toStringAsFixed(0)} lbs'
                    : 'BW';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatSnakeCase(exerciseId),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$sets x $reps  ·  $weightStr',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSnakeCase(String s) {
    return s
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
