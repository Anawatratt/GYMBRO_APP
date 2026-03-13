import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

// ── Providers ────────────────────────────────────────────

final _historyByUidProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, uid) {
  return FirebaseFirestore.instance
      .collection('workout_history')
      .where('user_id', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final docs = s.docs.map((d) => d.data()).toList();
        docs.sort((a, b) {
          final ta = a['completed_at'];
          final tb = b['completed_at'];
          if (ta is Timestamp && tb is Timestamp) {
            return tb.compareTo(ta); // descending
          }
          return 0;
        });
        return docs;
      });
});

// Returns Map<exerciseId, {primary: group, secondary: [group, ...]}>
final _exerciseMapProvider =
    FutureProvider<Map<String, _ExerciseGroups>>((ref) async {
  final snap =
      await FirebaseFirestore.instance.collection('exercises').get();
  final map = <String, _ExerciseGroups>{};
  for (final doc in snap.docs) {
    final muscles = doc.data()['muscle_involvements'] as List? ?? [];
    String primary = 'Other';
    final secondary = <String>[];
    for (final m in muscles) {
      final involvement = (m as Map)['involvement_type'] as String? ?? '';
      final name = m['muscle_name'] as String? ?? '';
      final group = _toGroup(name);
      if (involvement == 'primary' && primary == 'Other') {
        primary = group;
      } else if (involvement != 'primary' && group != primary) {
        if (!secondary.contains(group)) secondary.add(group);
      }
    }
    map[doc.id] = _ExerciseGroups(primary: primary, secondary: secondary);
  }
  return map;
});

class _ExerciseGroups {
  final String primary;
  final List<String> secondary;
  const _ExerciseGroups({required this.primary, required this.secondary});
}

String _toGroup(String muscle) {
  const g = {
    'Pectoralis Major': 'Chest',   'Pectoralis Minor': 'Chest',
    'Latissimus Dorsi': 'Back',    'Trapezius': 'Back',
    'Rhomboids': 'Back',           'Erector Spinae': 'Back',
    'Anterior Deltoid': 'Shoulders', 'Lateral Deltoid': 'Shoulders',
    'Posterior Deltoid': 'Shoulders',
    'Biceps Brachii': 'Arms',      'Triceps Brachii': 'Arms',
    'Brachialis': 'Arms',
    'Quadriceps': 'Legs',          'Hamstrings': 'Legs',
    'Glutes': 'Legs',              'Calves': 'Legs',
    'Adductors': 'Legs',
    'Rectus Abdominis': 'Core',    'Obliques': 'Core',
    'Transverse Abdominis': 'Core',
  };
  return g[muscle] ?? 'Other';
}

String _fmt(String s) => s
    .split('_')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

const _groupColors = {
  'Chest':     Color(0xFFE53935),
  'Back':      Color(0xFF3F51B5),
  'Legs':      Color(0xFFEF9A9A),
  'Shoulders': Color(0xFF757575),
  'Arms':      Color(0xFFB71C1C),
  'Core':      Color(0xFFBDBDBD),
  'Other':     Color(0xFFE0E0E0),
};

const _groupOrder = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

// ── TimeFrame ────────────────────────────────────────────

enum _TimeFrame { day, week, month, year }

extension _TimeFrameLabel on _TimeFrame {
  String get label {
    switch (this) {
      case _TimeFrame.day:   return '1D';
      case _TimeFrame.week:  return '7D';
      case _TimeFrame.month: return '30D';
      case _TimeFrame.year:  return '1Y';
    }
  }

  int get days {
    switch (this) {
      case _TimeFrame.day:   return 1;
      case _TimeFrame.week:  return 7;
      case _TimeFrame.month: return 30;
      case _TimeFrame.year:  return 365;
    }
  }
}

// ── Screen ───────────────────────────────────────────────

class ProgressAnalyticsScreen extends ConsumerStatefulWidget {
  final String? viewUid;
  const ProgressAnalyticsScreen({super.key, this.viewUid});

  @override
  ConsumerState<ProgressAnalyticsScreen> createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState
    extends ConsumerState<ProgressAnalyticsScreen> {
  int _touchedIndex = -1;
  _TimeFrame _timeFrame = _TimeFrame.month;

  @override
  Widget build(BuildContext context) {
    final uid =
        widget.viewUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = widget.viewUid != null
        ? ref.watch(userByUidProvider(uid))
        : ref.watch(currentUserDocProvider);
    final histAsync = ref.watch(_historyByUidProvider(uid));
    final exMapAsync = ref.watch(_exerciseMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: histAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (history) {
          if (history.isEmpty) return _emptyState();
          final profile = profileAsync.value;
          return exMapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _body(context, profile, history, {}),
            data: (exMap) => _body(context, profile, history, exMap),
          );
        },
      ),
    );
  }

  // ── Compute ─────────────────────────────────────────────

  Map<String, int> _computeGroupSets(
      List<Map<String, dynamic>> history,
      Map<String, _ExerciseGroups> exMap,
      bool includeSecondary) {
    final totals = <String, int>{};
    for (final session in history) {
      for (final ex in (session['exercises'] as List? ?? [])) {
        final m = ex as Map<String, dynamic>;
        final exId = m['exercise_id'] as String? ?? '';
        final sets = (m['sets'] as num?)?.toInt() ?? 0;
        final groups = exMap[exId];
        if (groups == null) continue;
        totals[groups.primary] = (totals[groups.primary] ?? 0) + sets;
        if (includeSecondary) {
          for (final sg in groups.secondary) {
            totals[sg] = (totals[sg] ?? 0) + (sets ~/ 2);
          }
        }
      }
    }
    return totals;
  }

  /// Compute volume timeline spots for the area chart.
  /// week  → 7 daily buckets
  /// month → 10 buckets of 3 days each
  /// year  → 12 monthly buckets
  List<double> _computeVolumeTimeline(
      List<Map<String, dynamic>> history, _TimeFrame tf) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: tf.days));

    // Filter sessions within the timeframe
    final filtered = history.where((s) {
      final ts = s['completed_at'];
      if (ts is! Timestamp) return false;
      return ts.toDate().isAfter(cutoff);
    }).toList();

    late int bucketCount;
    late double Function(DateTime dt) bucketIndex;

    switch (tf) {
      case _TimeFrame.day:
        bucketCount = 24;
        bucketIndex = (dt) {
          final diff = now.difference(dt).inHours;
          final idx = (23 - diff).clamp(0, 23);
          return idx.toDouble();
        };
        break;
      case _TimeFrame.week:
        bucketCount = 7;
        bucketIndex = (dt) {
          final diff = now.difference(dt).inDays;
          final idx = (tf.days - 1 - diff).clamp(0, bucketCount - 1);
          return idx.toDouble();
        };
        break;
      case _TimeFrame.month:
        bucketCount = 10;
        bucketIndex = (dt) {
          final diff = now.difference(dt).inDays;
          final idx = ((tf.days - 1 - diff) ~/ 3).clamp(0, bucketCount - 1);
          return idx.toDouble();
        };
        break;
      case _TimeFrame.year:
        bucketCount = 12;
        bucketIndex = (dt) {
          // Map to month bucket: 0 = oldest month, 11 = current month
          int monthDiff = (now.year - dt.year) * 12 + (now.month - dt.month);
          final idx = (11 - monthDiff).clamp(0, bucketCount - 1);
          return idx.toDouble();
        };
        break;
    }

    final buckets = List<double>.filled(bucketCount, 0.0);

    for (final session in filtered) {
      final ts = session['completed_at'] as Timestamp;
      final dt = ts.toDate();
      final idx = bucketIndex(dt).toInt();
      double sessionVolume = 0;
      for (final ex in (session['exercises'] as List? ?? [])) {
        final m = ex as Map<String, dynamic>;
        final sets = (m['sets'] as num?)?.toDouble() ?? 0;
        final reps = (m['reps'] as num?)?.toDouble() ?? 0;
        final weight = (m['weight'] as num?)?.toDouble();
        if (weight != null && weight > 0) {
          sessionVolume += sets * reps * weight;
        } else {
          sessionVolume += sets * reps;
        }
      }
      buckets[idx] += sessionVolume;
    }

    return buckets;
  }

  /// Total volume across ALL history (sets × reps × weight).
  String _computeTotalVolume(List<Map<String, dynamic>> history) {
    double total = 0;
    for (final session in history) {
      for (final ex in (session['exercises'] as List? ?? [])) {
        final m = ex as Map<String, dynamic>;
        final sets = (m['sets'] as num?)?.toDouble() ?? 0;
        final reps = (m['reps'] as num?)?.toDouble() ?? 0;
        final weight = (m['weight'] as num?)?.toDouble();
        if (weight != null && weight > 0) {
          total += sets * reps * weight;
        } else {
          total += sets * reps;
        }
      }
    }
    if (total >= 1000) {
      final k = total / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return total.toInt().toString();
  }

  // ── Body ────────────────────────────────────────────────

  // Filter history by current timeframe
  List<Map<String, dynamic>> _filterHistory(List<Map<String, dynamic>> history) {
    final cutoff = DateTime.now().subtract(Duration(days: _timeFrame.days));
    return history.where((s) {
      final ts = s['completed_at'];
      return ts is Timestamp && ts.toDate().isAfter(cutoff);
    }).toList();
  }

  Widget _body(
    BuildContext context,
    AppUser? profile,
    List<Map<String, dynamic>> history,
    Map<String, _ExerciseGroups> exMap,
  ) {
    final filtered = _filterHistory(history);

    final groupSets = _computeGroupSets(filtered, exMap, false);
    final volumeSpots = _computeVolumeTimeline(filtered, _timeFrame);
    final totalVolume = _computeTotalVolume(filtered);

    final totalSessions = filtered.length;
    final totalExercises = filtered.fold(
        0, (s, h) => s + ((h['exercises'] as List?)?.length ?? 0));

    // Build the ordered list for donut/breakdown
    final ordered = _groupOrder
        .where((g) => groupSets.containsKey(g))
        .toList()
      ..addAll(groupSets.keys
          .where((k) => !_groupOrder.contains(k))
          .toList());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Profile banner
        _profileBanner(profile),
        const SizedBox(height: 16),

        // ── Timeframe selector (controls all charts) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: _TimeFrame.values.map((tf) {
              final isActive = tf == _timeFrame;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _timeFrame = tf;
                    _touchedIndex = -1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE53935)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tf.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Stats row: 3 tiles in one box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _StatTile(
                  icon: Icons.event_available,
                  color: const Color(0xFFE53935),
                  value: '$totalSessions',
                  label: 'Sessions')),
              VerticalDivider(width: 1, thickness: 1, color: const Color(0xFF2C2C2E)),
              Expanded(child: _StatTile(
                  icon: Icons.fitness_center,
                  color: const Color(0xFF444444),
                  value: '$totalExercises',
                  label: 'Exercises')),
              VerticalDivider(width: 1, thickness: 1, color: const Color(0xFF2C2C2E)),
              Expanded(child: _StatTile(
                  icon: Icons.bolt,
                  color: const Color(0xFFE53935),
                  value: totalVolume,
                  label: 'Total Volume')),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // Training Analysis section
        const _SectionHeader(title: 'Training Analysis'),
        const SizedBox(height: 12),

        // Side-by-side: compact donut card + area chart card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompactDonutCard(
                groupSets: groupSets,
                ordered: ordered,
                touchedIndex: _touchedIndex,
                onTouch: (i) => setState(() => _touchedIndex = i),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AreaChartCard(
                buckets: volumeSpots,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Volume Breakdown bars card
        if (groupSets.isNotEmpty)
          _VolumeBreakdownCard(
            groupSets: groupSets,
            ordered: ordered,
            touchedIndex: _touchedIndex,
          ),
        const SizedBox(height: 28),

        // Workout History
        const _SectionHeader(title: 'Workout History'),
        const SizedBox(height: 14),
        ...history.take(5).map((s) => _HistoryCard(data: s)),
        if (history.length > 5)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/workoutHistory'),
            child: const Text('See all',
                style: TextStyle(color: Color(0xFFE53935), fontSize: 14)),
          ),
      ],
    );
  }

  Widget _profileBanner(AppUser? profile) {
    const color = Color(0xFFE53935);
    final photoUrl = (profile?.photoUrl.isNotEmpty == true) ? profile!.photoUrl : null;
    final name = (profile?.displayName.isNotEmpty == true) ? profile!.displayName : 'User';
    final initials = name != 'User' ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(children: [
        photoUrl != null
            ? CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(photoUrl),
              )
            : CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("$name's Progress",
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text('Real-time from workout logs',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
      ]),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text('No workout logs yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          const SizedBox(height: 4),
          Text('Complete a session to see progress',
              style: TextStyle(color: Colors.grey[350], fontSize: 13)),
        ]),
      );
}

// ── Compact Donut Card ────────────────────────────────────

class _CompactDonutCard extends StatelessWidget {
  final Map<String, int> groupSets;
  final List<String> ordered;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _CompactDonutCard({
    required this.groupSets,
    required this.ordered,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final sections = ordered.asMap().entries.map((entry) {
      final i = entry.key;
      final g = entry.value;
      final sets = groupSets[g] ?? 0;
      final isTouched = i == touchedIndex;
      final color = _groupColors[g] ?? const Color(0xFF90A4AE);
      return PieChartSectionData(
        color: color,
        value: sets.toDouble(),
        title: '',
        radius: isTouched ? 52.0 : 42.0,
        badgeWidget: null,
      );
    }).toList();

    final centerLabel = touchedIndex >= 0 && touchedIndex < ordered.length
        ? ordered[touchedIndex]
        : 'Sets';
    final centerColor = touchedIndex >= 0 && touchedIndex < ordered.length
        ? (_groupColors[ordered[touchedIndex]] ?? Colors.grey)
        : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Muscle Groups',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          // Donut chart
          if (groupSets.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text('No data',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            onTouch(-1);
                            return;
                          }
                          onTouch(
                              response.touchedSection!.touchedSectionIndex);
                        },
                      ),
                      sections: sections,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel,
                        style: TextStyle(
                          fontSize: touchedIndex >= 0 ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: centerColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Area Chart Card (Stock-style line chart) ─────────────

class _AreaChartCard extends StatelessWidget {
  final List<double> buckets;
  const _AreaChartCard({required this.buckets});

  String _formatY(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0xFFE53935);
    final hasData = buckets.any((v) => v > 0);
    final maxY = hasData ? buckets.reduce(math.max) : 1.0;

    final spots = buckets.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Volume',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.25,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.grey.withAlpha(20), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: maxY / 2,
                            getTitlesWidget: (v, _) {
                              if (v == 0) return const SizedBox.shrink();
                              return Text(_formatY(v),
                                  style: TextStyle(
                                      fontSize: 8, color: Colors.grey[400]));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 14,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i != 0 && i != buckets.length - 1) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(i == 0 ? 'Older' : 'Now',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.grey[400])),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: lineColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, _) =>
                                spot.x == buckets.length - 1.0,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                                    radius: 4,
                                    color: lineColor,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                lineColor.withAlpha(90),
                                lineColor.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              Colors.black.withAlpha(220),
                          getTooltipItems: (touchedSpots) => touchedSpots
                              .map((s) => LineTooltipItem(
                                    _formatY(s.y),
                                    const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                  ))
                              .toList(),
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  )
                : Center(
                    child: Text('No data',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12))),
          ),
        ],
      ),
    );
  }
}

// ── Volume Breakdown Card ─────────────────────────────────

class _VolumeBreakdownCard extends StatelessWidget {
  final Map<String, int> groupSets;
  final List<String> ordered;
  final int touchedIndex;

  const _VolumeBreakdownCard({
    required this.groupSets,
    required this.ordered,
    required this.touchedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final total = groupSets.values.fold(0, (a, b) => a + b);
    final maxSets = groupSets.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volume Breakdown',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 14),
          ...ordered.asMap().entries.map((entry) {
            final i = entry.key;
            final g = entry.value;
            final sets = groupSets[g] ?? 0;
            final ratio = maxSets > 0 ? sets / maxSets : 0.0;
            final pct = total > 0 ? (sets / total * 100).round() : 0;
            final color = _groupColors[g] ?? const Color(0xFF90A4AE);
            final isHighlighted =
                touchedIndex < 0 || i == touchedIndex;
            final isSelected = i == touchedIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: isHighlighted ? 1.0 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius:
                                      BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(g,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: Colors.white)),
                        ]),
                        Row(children: [
                          Text('$sets sets',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500)),
                          const SizedBox(width: 6),
                          Text('$pct%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: isSelected ? 10.0 : 7.0,
                        color: color,
                        backgroundColor: color.withAlpha(25),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white));
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      );
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
    final programName = data['program_name'] as String? ?? '';
    final sessionName = data['session_name'] as String? ?? '';
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFFE53935), size: 22),
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
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(dateStr,
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${exercises.length} exercises',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(width: 4),
            Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[400],
                size: 20),
          ]),
          if (_expanded && exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...exercises.map((ex) {
              final m = ex as Map<String, dynamic>;
              final exId = m['exercise_id'] as String? ?? '';
              final sets = m['sets'] ?? 0;
              final reps = m['reps'] ?? 0;
              final weight = m['weight'];
              final weightStr = weight != null
                  ? '${(weight as num).toStringAsFixed(0)} kg'
                  : 'BW';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.fitness_center,
                      size: 15, color: Colors.grey[400]),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_fmt(exId),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600))),
                  Text('$sets × $reps  ·  $weightStr',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 12)),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }
}
