import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/program_provider.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentUserDocProvider).value;
    final name = (appUser?.displayName.isNotEmpty == true)
        ? appUser!.displayName
        : 'Athlete';
    final programsAsync = ref.watch(programsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Plan')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Get ready to train, $name',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: programsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: TextStyle(color: Colors.grey[400])),
              ),
              data: (programs) {
                if (programs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('No programs found',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: programs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = programs[index];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/planDetail',
                        arguments: {
                          'programId': p.id,
                          'programName': p.programName,
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
                            Icon(p.goalIcon,
                                size: 28, color: Colors.grey[400]),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.programName,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(p.description,
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
                                      _mutedPill('${p.daysPerWeek} days/wk'),
                                      _mutedPill('${p.durationWeeks} weeks'),
                                      _mutedPill(_capitalize(
                                          p.difficultyLevel)),
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
