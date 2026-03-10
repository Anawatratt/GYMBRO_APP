import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Reuse the same providers from progress_analytics_screen
final _historyStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('workout_history')
      .snapshots();
});

final _exerciseMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final snap =
      await FirebaseFirestore.instance.collection('exercises').get();
  final map = <String, String>{};
  for (final doc in snap.docs) {
    final data = doc.data();
    final involvements =
        data['muscle_involvements'] as List<dynamic>? ?? [];
    if (involvements.isNotEmpty) {
      final primary = involvements.firstWhere(
        (m) => (m as Map)['involvement_type'] == 'primary',
        orElse: () => involvements.first,
      ) as Map;
      map[doc.id] = _toGroup(primary['muscle_name'] as String? ?? '');
    }
  }
  return map;
});

String _toGroup(String muscle) {
  final m = muscle.toLowerCase();
  if (m.contains('pec') || m.contains('chest')) return 'Chest';
  if (m.contains('lat') || m.contains('trap') || m.contains('rhomb') ||
      m.contains('back') || m.contains('rear') || m.contains('teres')) {
    return 'Back';
  }
  if (m.contains('quad') || m.contains('hamstring') || m.contains('glute') ||
      m.contains('leg') || m.contains('hip')) { return 'Legs'; }
  if (m.contains('delt') || m.contains('shoulder')) { return 'Shoulders'; }
  if (m.contains('bicep') || m.contains('tricep') || m.contains('forearm') ||
      m.contains('arm')) { return 'Arms'; }
  if (m.contains('ab') || m.contains('core') || m.contains('oblique') ||
      m.contains('erector')) { return 'Core'; }
  return 'Other';
}

const _groupColors = {
  'Chest':     Color(0xFFE53935),
  'Back':      Color(0xFF3F51B5),
  'Legs':      Color(0xFFEF9A9A),
  'Shoulders': Color(0xFF757575),
  'Arms':      Color(0xFFB71C1C),
  'Core':      Color(0xFFBDBDBD),
};

class ProgressBreakdownScreen extends ConsumerWidget {
  const ProgressBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyStreamProvider);
    final exerciseMapAsync = ref.watch(_exerciseMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Muscle Breakdown')),
      body: exerciseMapAsync.when(
        data: (exMap) => historyAsync.when(
          data: (snap) {
            final groupSets = <String, int>{};
            for (final doc in snap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final exercises = data['exercises'] as List<dynamic>? ?? [];
              for (final ex in exercises) {
                final exData = ex as Map<String, dynamic>;
                final exId = exData['exercise_id'] as String? ?? '';
                final sets = (exData['sets'] as num?)?.toInt() ?? 0;
                final group = exMap[exId] ?? 'Other';
                groupSets[group] = (groupSets[group] ?? 0) + sets;
              }
            }

            final maxSets =
                groupSets.values.fold(0, (a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const SizedBox(height: 8),
                Text('Volume by Muscle Group',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Based on total sets from workout history',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[400])),
                const SizedBox(height: 20),

                const Text('Large Muscle Groups',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 12),
                for (final g in ['Chest', 'Back', 'Legs', 'Shoulders'])
                  _MuscleBar(
                    label: g,
                    sets: groupSets[g] ?? 0,
                    maxSets: maxSets,
                    color: _groupColors[g] ?? Colors.grey,
                  ),
                const SizedBox(height: 20),

                const Text('Small Muscle Groups',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 12),
                for (final g in ['Arms', 'Core'])
                  _MuscleBar(
                    label: g,
                    sets: groupSets[g] ?? 0,
                    maxSets: maxSets,
                    color: _groupColors[g] ?? Colors.grey,
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MuscleBar extends StatelessWidget {
  final String label;
  final int sets;
  final int maxSets;
  final Color color;

  const _MuscleBar({
    required this.label,
    required this.sets,
    required this.maxSets,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxSets == 0 ? 0.0 : sets / maxSets;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text('$sets sets',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              color: color,
              backgroundColor: color.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}
