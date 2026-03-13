import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'notes_screen.dart';
import 'progress_analytics_screen.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final friendUid = args?['uid'] as String? ?? '';
    final friendName = args?['name'] as String? ?? 'Friend';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(friendName),
          bottom: const TabBar(
            labelColor: Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE53935),
            tabs: [
              Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Progress'),
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Plan'),
              Tab(icon: Icon(Icons.sticky_note_2_rounded), text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Progress tab — reuse ProgressAnalyticsScreen content
            ProgressAnalyticsScreen(viewUid: friendUid),
            // Plan tab — view-only plan
            _FriendPlanTab(uid: friendUid),
            // Notes tab — view-only
            NotesScreen(viewUid: friendUid),
          ],
        ),
      ),
    );
  }
}

// ── Plan tab: shows friend's active program (view-only) ──

class _FriendPlanTab extends ConsumerWidget {
  final String uid;
  const _FriendPlanTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userByUidProvider(uid));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        final activeProgramId = profile?.activeProgramId;
        if (activeProgramId == null || activeProgramId.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No active program',
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 15)),
              ],
            ),
          );
        }
        return _ProgramSessionsView(programId: activeProgramId);
      },
    );
  }
}

class _ProgramSessionsView extends StatefulWidget {
  final String programId;
  const _ProgramSessionsView({required this.programId});

  @override
  State<_ProgramSessionsView> createState() => _ProgramSessionsViewState();
}

class _ProgramSessionsViewState extends State<_ProgramSessionsView> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('programs')
          .doc(widget.programId)
          .collection('sessions')
          .orderBy('day_number')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data?.docs ?? [];
        if (sessions.isEmpty) {
          return Center(
            child: Text('No sessions',
                style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          );
        }

        if (_selectedIdx >= sessions.length) _selectedIdx = 0;

        final currentSession =
            sessions[_selectedIdx].data() as Map<String, dynamic>;
        final exercises =
            currentSession['exercises'] as List<dynamic>? ?? [];

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
                  final s =
                      sessions[index].data() as Map<String, dynamic>;
                  final isSelected = index == _selectedIdx;
                  final split = s['workout_split'] ?? '';
                  final dayNum = s['day_number'] ?? (index + 1);

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedIdx = index),
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE53935)
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
                          Text('Day',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[500],
                                fontSize: 11,
                              )),
                          const SizedBox(height: 2),
                          Text('$dayNum',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              )),
                          Text(split,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white60
                                    : Colors.grey[400],
                                fontSize: 10,
                              )),
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
                    child: Text(
                      currentSession['session_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${exercises.length} exercises',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
            ),

            // Exercise list (view-only)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ex =
                      exercises[index] as Map<String, dynamic>;
                  final exerciseId =
                      ex['exercise_id'] as String? ?? '';
                  final sets = ex['sets'] ?? 0;
                  final reps = ex['reps'] ?? 0;
                  final weight = ex['weight'];
                  final weightStr = weight != null
                      ? '${(weight as num).toStringAsFixed(0)} lbs'
                      : 'BW';
                  final restSec = ex['rest_seconds'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center,
                            size: 20, color: const Color(0xFF9E9E9E)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fmt(exerciseId),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$sets x $reps  ·  $weightStr  ·  ${restSec}s rest',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmt(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
