import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/storage_image.dart';
import '../widgets/exercise_detail_sheet.dart';

class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({super.key});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late int _selectedDay; // 1–7, auto = today's plan day
  final Set<String> _completedSessions = {};
  final Set<String> _checkedExercises = {}; // "$sessionKey-$index"
  bool _saving = false;
  bool _todayAlreadyLogged = false;
  final ScrollController _dayScrollController = ScrollController();

  Stream<QuerySnapshot>? _sessionsStream;
  String? _programId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday.clamp(1, 7);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDay(_selectedDay));
    _checkTodayLogged();
  }

  Future<void> _checkTodayLogged() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final ts = snap.data()?['lastWorkoutDate'] as Timestamp?;
    if (ts == null) return;
    final last = ts.toDate();
    final now = DateTime.now();
    final sameDay = last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    if (sameDay && mounted) {
      setState(() => _todayAlreadyLogged = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newId = args?['programId'] as String? ?? '';
    if (newId != _programId) {
      _programId = newId;
      _sessionsStream = FirebaseFirestore.instance
          .collection('programs')
          .doc(_programId)
          .collection('sessions')
          .orderBy('day_number')
          .snapshots();
    }
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToDay(int day) {
    const itemW = 80.0;
    final screenW = MediaQuery.of(context).size.width;
    final offset = (day - 1) * itemW - (screenW / 2) + itemW / 2;
    _dayScrollController.animateTo(
      offset.clamp(0.0, double.infinity),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Day 1 = Monday of this week
  DateTime get _planStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  DateTime _dayDate(int day) => _planStart.add(Duration(days: day - 1));

  bool _isToday(int day) {
    final d = _dayDate(day);
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  String _monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  int _weekNumber(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
  }

  Future<void> _markComplete({
    required String programName,
    required String sessionName,
    required String sessionKey,
    required List<dynamic> exercises,
  }) async {
    if (_completedSessions.contains(sessionKey)) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await FirebaseFirestore.instance.collection('workout_history').add({
      'program_name': programName,
      'session_name': sessionName,
      'completed_at': FieldValue.serverTimestamp(),
      'user_id': uid,
      'exercises': exercises
          .map(
            (e) => {
              'exercise_id': e['exercise_id'],
              'sets': e['sets'],
              'reps': e['reps'],
              'weight': e['weight'],
            },
          )
          .toList(),
    });

    // Update streak based on last workout date (not log count)
    if (uid.isNotEmpty) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final data = userSnap.data() ?? {};

      final todayDate = DateTime.now();
      final todayOnly = DateTime(todayDate.year, todayDate.month, todayDate.day);

      final lastWorkoutTs = data['lastWorkoutDate'] as Timestamp?;
      final lastWorkoutDate = lastWorkoutTs?.toDate();
      final lastWorkoutOnly = lastWorkoutDate != null
          ? DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day)
          : null;

      // Only update streak if we haven't already logged today
      if (lastWorkoutOnly == null || lastWorkoutOnly.isBefore(todayOnly)) {
        final currentStreak = data['dayStreak'] as int? ?? 0;
        final yesterday = todayOnly.subtract(const Duration(days: 1));

        // Streak continues if last workout was yesterday, resets otherwise
        final newStreak = (lastWorkoutOnly != null && lastWorkoutOnly == yesterday)
            ? currentStreak + 1
            : 1;

        await userRef.update({
          'dayStreak': newStreak,
          'lastWorkoutDate': FieldValue.serverTimestamp(),
          if (_programId != null) 'active_program_id': _programId,
        });
      } else if (_programId != null) {
        // Already logged today — just update active program
        await userRef.update({'active_program_id': _programId});
      }
    }

    setState(() {
      _completedSessions.add(sessionKey);
      _todayAlreadyLogged = true;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final programName = args?['programName'] as String? ?? 'Workout Plan';

    return Scaffold(
      appBar: AppBar(title: Text(programName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sessionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessionDocs = snapshot.data?.docs ?? [];

          // Build map: day_number → doc
          final Map<int, QueryDocumentSnapshot> sessionByDay = {};
          for (final doc in sessionDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final dayNum = data['day_number'] as int? ?? 0;
            if (dayNum >= 1 && dayNum <= 7) {
              sessionByDay[dayNum] = doc;
            }
          }

          if (sessionByDay.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'No sessions in this program',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // Clamp selected day
          if (!sessionByDay.containsKey(_selectedDay) &&
              sessionByDay.isNotEmpty) {
            final firstWorkoutDay = sessionByDay.keys.reduce(
              (a, b) => a < b ? a : b,
            );
            if (_selectedDay < firstWorkoutDay || _selectedDay > 7) {
              _selectedDay = firstWorkoutDay;
            }
          }

          final isRestDay = !sessionByDay.containsKey(_selectedDay);
          final currentDoc = isRestDay ? null : sessionByDay[_selectedDay];
          final currentSession =
              currentDoc?.data() as Map<String, dynamic>? ?? {};
          final exercises =
              (currentSession['exercises'] as List<dynamic>? ?? []);
          exercises.sort(
            (a, b) =>
                (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0),
          );
          final sessionKey = currentDoc?.id ?? '';
          final isDone = _completedSessions.contains(sessionKey);

          return Column(
            children: [
              // ── Physical Calendar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4)),
                      BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 2, offset: const Offset(0, 1)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Red header ──
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              _monthYear(_planStart),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'WEEK ${_weekNumber(_planStart)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Binding holes ──
                      Container(
                        height: 10,
                        color: const Color(0xFF252525),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(18, (_) => Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111111),
                              shape: BoxShape.circle,
                            ),
                          )),
                        ),
                      ),
                      // ── Big scrollable day cards ──
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          controller: _dayScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          itemCount: 7,
                          itemExtent: 82,
                          itemBuilder: (context, index) {
                            final day = index + 1;
                            final hasSession = sessionByDay.containsKey(day);
                            final isSelected = day == _selectedDay;
                            final sessionId = hasSession ? sessionByDay[day]!.id : null;
                            final isSessionDone = sessionId != null && _completedSessions.contains(sessionId);
                            final sessionData = hasSession
                                ? sessionByDay[day]!.data() as Map<String, dynamic>
                                : null;
                            final split = sessionData?['workout_split'] as String? ?? '';
                            final isToday = _isToday(day);
                            final weekday = _weekdays[_dayDate(day).weekday - 1];

                            const calRed = Color(0xFFD32F2F);
                            const doneColor = Color(0xFFE53935);

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedDay = day);
                                _scrollToDay(day);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? calRed
                                      : isSessionDone
                                          ? doneColor.withAlpha(20)
                                          : isToday
                                              ? calRed.withAlpha(10)
                                              : const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? calRed
                                        : isToday
                                            ? calRed.withAlpha(100)
                                            : const Color(0xFF2C2C2E),
                                    width: isSelected || isToday ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: calRed.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Weekday
                                    Text(
                                      weekday.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: isSelected
                                            ? Colors.white70
                                            : isToday
                                                ? calRed
                                                : Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Big number
                                    Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                        color: isSelected
                                            ? Colors.white
                                            : isSessionDone
                                                ? doneColor
                                                : isToday
                                                    ? calRed
                                                    : const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Split / done
                                    isSessionDone
                                        ? Icon(Icons.check_circle_rounded, size: 14, color: doneColor)
                                        : Text(
                                            hasSession
                                                ? split.isNotEmpty ? split : '●'
                                                : '—',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white70
                                                  : hasSession
                                                      ? const Color(0xFF9E9E9E)
                                                      : const Color(0xFF6B6B6B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ──
              if (isRestDay)
                _RestDayContent(day: _selectedDay)
              else ...[
                // Session header + progress
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentSession['session_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${_checkedExercises.where((k) => k.startsWith('$sessionKey-')).length}/${exercises.length}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: exercises.isEmpty
                              ? 0
                              : _checkedExercises.where((k) => k.startsWith('$sessionKey-')).length /
                                  exercises.length,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF252525),
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),

                // Exercise list
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
                      final checkKey = '$sessionKey-$index';
                      final isChecked = _checkedExercises.contains(checkKey);

                      final weightStr = weight != null
                          ? '${(weight as num).toStringAsFixed(0)} kg'
                          : 'BW';
                      final muscle = _muscleTag(exerciseId);
                      final desaturate = isDone || isChecked;

                      return Container(
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFF252525) : const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isChecked ? 8 : 18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (!isDone) {
                              setState(() {
                                if (isChecked) {
                                  _checkedExercises.remove(checkKey);
                                } else {
                                  _checkedExercises.add(checkKey);
                                }
                              });
                            }
                          },
                          onLongPress: () => showExerciseDetailSheet(
                            context,
                            exerciseId: exerciseId,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Exercise image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: ColorFiltered(
                                  colorFilter: desaturate
                                      ? const ColorFilter.matrix([
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0,      0,      0,      1, 0,
                                        ])
                                      : const ColorFilter.mode(
                                          Colors.transparent, BlendMode.color),
                                  child: StorageImage(
                                    key: ValueKey(exerciseId),
                                    storagePath: exerciseImagePath(exerciseId),
                                    width: 140,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    cropTop: 0,
                                    placeholder: Container(
                                      width: 140,
                                      height: 120,
                                      color: const Color(0xFF252525),
                                      child: Icon(Icons.fitness_center,
                                          size: 28, color: const Color(0xFF6B6B6B)),
                                    ),
                                  ),
                                ),
                              ),
                              // Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (muscle.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53935)
                                                .withAlpha(18),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            muscle,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFE53935),
                                            ),
                                          ),
                                        ),
                                      Text(
                                        _formatSnakeCase(exerciseId),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: desaturate
                                              ? const Color(0xFF6B6B6B)
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$sets × $reps  ·  $weightStr',
                                        style: const TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 12),
                                      ),
                                      if (restSec > 0)
                                        Text(
                                          'Rest ${restSec}s',
                                          style: const TextStyle(
                                              color: Color(0xFF6B6B6B),
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Checkmark
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isChecked || isDone
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFFE53935),
                                          size: 24,
                                          key: ValueKey('done'))
                                      : Icon(Icons.radio_button_unchecked,
                                          color: Colors.grey[300],
                                          size: 24,
                                          key: const ValueKey('undone')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom slide-to-log
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _SlideToLog(
                    isDone: isDone,
                    isSaving: _saving,
                    isFutureDay: _selectedDay > DateTime.now().weekday,
                    isPastDay: _selectedDay < DateTime.now().weekday,
                    todayAlreadyLogged: _isToday(_selectedDay) && _todayAlreadyLogged && !isDone,
                    onCompleted: () => _markComplete(
                      programName: programName,
                      sessionName: currentSession['session_name'] ?? '',
                      sessionKey: sessionKey,
                      exercises: exercises,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatSnakeCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  String _muscleTag(String id) {
    if (id.contains('bench') || id.contains('chest') || id.contains('fly') ||
        id.contains('pec') || id.contains('incline')) { return 'Chest'; }
    if (id.contains('row') || id.contains('pulldown') || id.contains('pull_up') ||
        id.contains('lat_pull') || id.contains('straight_arm')) { return 'Back'; }
    if (id.contains('squat') || id.contains('leg_press') || id.contains('leg_curl') ||
        id.contains('leg_extension') || id.contains('calf') ||
        id.contains('deadlift') || id.contains('romanian') ||
        id.contains('lunge')) { return 'Legs'; }
    if (id.contains('shoulder') || id.contains('lateral') ||
        id.contains('face_pull') || id.contains('overhead_press') ||
        id.contains('front_raise') || id.contains('delt')) { return 'Shoulders'; }
    if (id.contains('curl') || id.contains('bicep') || id.contains('tricep') ||
        id.contains('pushdown') || id.contains('kickback')) { return 'Arms'; }
    if (id.contains('crunch') || id.contains('plank') ||
        id.contains('oblique') || id.contains('ab')) { return 'Core'; }
    return '';
  }
}

// ── Rest Day Content ─────────────────────────────────────

class _RestDayContent extends StatelessWidget {
  final int day;
  const _RestDayContent({required this.day});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hotel_rounded, size: 48, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          Text(
            'Day $day/7 — Rest Day',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take it easy today.\nRecovery is part of the program.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'REST DAY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.grey[500],
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide To Log ──────────────────────────────────────────

class _SlideToLog extends StatefulWidget {
  final bool isDone;
  final bool isSaving;
  final bool isFutureDay;
  final bool isPastDay;
  final bool todayAlreadyLogged;
  final VoidCallback onCompleted;

  const _SlideToLog({
    required this.isDone,
    required this.isSaving,
    required this.isFutureDay,
    required this.isPastDay,
    required this.todayAlreadyLogged,
    required this.onCompleted,
  });

  @override
  State<_SlideToLog> createState() => _SlideToLogState();
}

class _SlideToLogState extends State<_SlideToLog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  bool _triggered = false;
  late AnimationController _resetAnim;
  late Animation<double> _resetProgress;

  @override
  void initState() {
    super.initState();
    _resetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _resetProgress = Tween<double>(begin: 0, end: 0).animate(_resetAnim)
      ..addListener(() => setState(() => _progress = _resetProgress.value));
  }

  @override
  void dispose() {
    _resetAnim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double maxW) {
    if (widget.isDone || _triggered) return;
    setState(() {
      _progress = (_progress + d.delta.dx / maxW).clamp(0.0, 1.0);
    });
    if (_progress >= 0.88 && !_triggered) {
      _triggered = true;
      widget.onCompleted();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    if (_triggered) return;
    _resetProgress = Tween<double>(begin: _progress, end: 0.0)
        .animate(CurvedAnimation(parent: _resetAnim, curve: Curves.easeOut));
    _resetAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // ── Locked states ──────────────────────────────────────
    if (widget.isFutureDay || widget.isPastDay) {
      final label = widget.isFutureDay ? 'Available on this day' : 'Past day — cannot log';
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isFutureDay ? Icons.lock_clock_outlined : Icons.history,
              color: const Color(0xFF6B6B6B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.todayAlreadyLogged) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF6B6B6B), size: 18),
            SizedBox(width: 8),
            Text(
              'Already logged today',
              style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isDone) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Workout Logged',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      const thumbSize = 48.0;
      const trackH = 56.0;
      const activeColor = Color(0xFFE53935);

      final thumbX = _progress * (maxW - thumbSize - 8);

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxW - thumbSize),
        onHorizontalDragEnd: _onDragEnd,
        child: Container(
          height: trackH,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2E)),
          ),
          child: Stack(
            children: [
              // Fill bar
              Container(
                width: thumbX + thumbSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: activeColor.withAlpha((_progress * 180).round()),
                ),
              ),
              // Label
              Center(
                child: Opacity(
                  opacity: (1 - _progress * 2).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: Color(0xFF6B6B6B)),
                      const SizedBox(width: 6),
                      Text(
                        widget.isSaving ? 'Logging...' : 'Slide to Log Workout',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: 4 + thumbX,
                top: (trackH - thumbSize) / 2,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: activeColor.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: widget.isSaving
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
