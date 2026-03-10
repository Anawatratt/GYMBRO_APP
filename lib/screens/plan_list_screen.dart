import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  IconData _goalIcon(String goal) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileName =
        ref.watch(userProfileProvider).value?.name ?? 'Athlete';

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Plan')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Get ready to train, $profileName',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('programs')
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
                        Icon(Icons.event_note, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('No programs found',
                            style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final programId = docs[index].id;
                    final name = data['program_name'] ?? '';
                    final desc = data['description'] ?? '';
                    final goal = data['goal'] ?? '';
                    final diff = data['difficulty_level'] ?? '';
                    final daysPerWeek = data['days_per_week'] ?? 0;
                    final durationWeeks = data['duration_weeks'] ?? 0;
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/planDetail',
                        arguments: {
                          'programId': programId,
                          'programName': name,
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(_goalIcon(goal),
                                size: 28, color: Colors.grey[400]),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(name,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(desc,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _mutedPill('$daysPerWeek days/wk'),
                                      _mutedPill('$durationWeeks weeks'),
                                      _mutedPill(_capitalize(diff)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right,
                                color: Colors.grey[600], size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutedPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
