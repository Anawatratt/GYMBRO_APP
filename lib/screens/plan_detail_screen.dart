import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  int _selectedSessionIndex = 0;
  final Set<String> _completedSessions = {};
  bool _saving = false;

  Future<void> _markComplete({
    required String programName,
    required String sessionName,
    required String sessionKey,
    required List<dynamic> exercises,
  }) async {
    if (_completedSessions.contains(sessionKey)) return;

    setState(() => _saving = true);

    final me = ref.read(currentUserDocProvider).value;
    final db = FirebaseFirestore.instance;

    // 1. Save workout history
    await db.collection('workout_history').add({
      'program_name': programName,
      'session_name': sessionName,
      'completed_at': FieldValue.serverTimestamp(),
      'user_uid': me?.uid ?? '',
      'user_name': me?.displayName ?? '',
      'exercises': exercises
          .map((e) => {
                'exercise_id': e['exercise_id'],
                'sets': e['sets'],
                'reps': e['reps'],
                'weight': e['weight'],
              })
          .toList(),
    });

    // 2. Notify all accepted friends
    if (me != null) {
      final friends = ref.read(friendsStreamProvider).value ?? [];
      final accepted = friends.where((f) => f.status == 'accepted').toList();

      if (accepted.isNotEmpty) {
        final now = Timestamp.now();
        final batch = db.batch();
        for (final friend in accepted) {
          final notifRef = db
              .collection('users')
              .doc(friend.friendUid)
              .collection('notifications')
              .doc();
          batch.set(notifRef, {
            'type': 'workout_complete',
            'fromUserId': me.uid,
            'fromUserName': me.displayName,
            'title': 'Workout Complete! 🏋️',
            'message': '${me.displayName} just finished "$sessionName"! 💪',
            'read': false,
            'actionDone': false,
            'createdAt': now,
          });
        }
        await batch.commit();
      }
    }

    setState(() {
      _completedSessions.add(sessionKey);
      _saving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sessionName completed! Friends notified 🎉'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final programId = args?['programId'] as String? ?? '';
    final programName = args?['programName'] as String? ?? 'Workout Plan';

    return Scaffold(
      appBar: AppBar(title: Text(programName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('programs')
            .doc(programId)
            .collection('sessions')
            .orderBy('day_number')
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
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No sessions in this program',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 15)),
                ],
              ),
            );
          }

          final sessions = snapshot.data!.docs;

          if (_selectedSessionIndex >= sessions.length) {
            _selectedSessionIndex = 0;
          }

          final currentSession =
              sessions[_selectedSessionIndex].data() as Map<String, dynamic>;
          final exercises =
              currentSession['exercises'] as List<dynamic>? ?? [];
          exercises.sort((a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

          final sessionKey = sessions[_selectedSessionIndex].id;
          final isDone = _completedSessions.contains(sessionKey);

          return Column(
            children: [
              // Session selector
              Container(
                height: 88,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session =
                        sessions[index].data() as Map<String, dynamic>;
                    final isSelected = index == _selectedSessionIndex;
                    final split = session['workout_split'] ?? '';
                    final dayNum = session['day_number'] ?? (index + 1);
                    final sessionDone =
                        _completedSessions.contains(sessions[index].id);

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedSessionIndex = index),
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: sessionDone
                              ? const Color(0xFF4CAF50)
                              : isSelected
                                  ? const Color(0xFF3F51B5)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (sessionDone
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFF3F51B5))
                                        .withAlpha(40),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (sessionDone)
                              const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                            else
                              Text(
                                'Day',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                color: (isSelected || sessionDone)
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              split,
                              style: TextStyle(
                                color: (isSelected || sessionDone)
                                    ? Colors.white60
                                    : Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Session header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSession['session_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          if ((currentSession['notes'] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                currentSession['notes'],
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Exercise list (read-only)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ex = exercises[index] as Map<String, dynamic>;
                    final exerciseId = ex['exercise_id'] as String? ?? '';
                    final sets = ex['sets'] ?? 0;
                    final reps = ex['reps'] ?? 0;
                    final weight = ex['weight'];
                    final restSec = ex['rest_seconds'] ?? 0;

                    final weightStr = weight != null
                        ? '${(weight as num).toStringAsFixed(0)} lbs'
                        : 'BW';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.grey[50]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center,
                              size: 20,
                              color: isDone
                                  ? Colors.grey[350]
                                  : Colors.grey[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatSnakeCase(exerciseId),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDone
                                        ? Colors.grey[400]
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$sets x $reps  ·  $weightStr  ·  ${restSec}s rest',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isDone)
                            Icon(Icons.check_circle,
                                color: const Color(0xFF4CAF50), size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom CTA
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isDone || _saving)
                        ? null
                        : () => _markComplete(
                              programName: programName,
                              sessionName:
                                  currentSession['session_name'] ?? '',
                              sessionKey: sessionKey,
                              exercises: exercises,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF3F51B5),
                      disabledBackgroundColor: const Color(0xFF4CAF50),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isDone
                                ? '✅ Completed!'
                                : 'Mark All Complete',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
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
