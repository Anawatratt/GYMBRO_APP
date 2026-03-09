import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ── Seed Runner ─────────────────────────────────────────
// เรียก seedAll() ครั้งเดียวเพื่อ seed ข้อมูลทั้งหมดเข้า Firestore
//
// วิธีใช้: ใน main.dart หลัง Firebase.initializeApp()
//   await seedAll();   // ลบออกหลัง seed เสร็จ

Future<void> seedAll() async {
  final db = FirebaseFirestore.instance;

  await seedUsers(db);
  await seedMuscles(db);
  await seedMuscleGroups(db);
  await seedMachines(db);
  await seedExercises(db);
  await seedPrograms(db);
  await seedWorkoutHistory(db);

  debugPrint('--- All seeding completed ---');
}

// ═══════════════════════════════════════════════════════════
// WORKOUT HISTORY — John Smith, ~2-3 months of PPL workouts
// ═══════════════════════════════════════════════════════════

Future<void> seedWorkoutHistory(FirebaseFirestore db) async {
  final auth = FirebaseAuth.instance;
  try {
    await auth.signInWithEmailAndPassword(
      email: 'john123@gymbro.internal',
      password: 'gymbro123',
    );
  } catch (e) {
    debugPrint('seedWorkoutHistory: could not sign in as John: $e');
    return;
  }

  // ใช้ Auth UID ตรงๆ เพื่อให้แน่ใจว่าตรงกับ currentUser ตอน login
  final uid = auth.currentUser!.uid;
  debugPrint('seedWorkoutHistory: John uid = $uid');

  // ลบ data เก่าทิ้งก่อน (force reseed)
  final oldDocs = await db.collection('workout_history').where('user_id', isEqualTo: uid).get();
  debugPrint('seedWorkoutHistory: deleting ${oldDocs.docs.length} old docs');
  for (final d in oldDocs.docs) { await d.reference.delete(); }

  final now = DateTime.now();
  DateTime d(int daysAgo, int hour) =>
      DateTime(now.year, now.month, now.day, hour, 0)
          .subtract(Duration(days: daysAgo));

  // ignore: prefer_function_declarations_over_variables
  Map<String, dynamic> s(String name, DateTime date, List<Map<String,dynamic>> exs) => {
    'user_id': uid,
    'program_name': 'PPL Program',
    'session_name': name,
    'completed_at': Timestamp.fromDate(date),
    'exercises': exs,
  };
  Map<String,dynamic> ex(String id, int sets, int reps, double weight) =>
      {'exercise_id': id, 'sets': sets, 'reps': reps, 'weight': weight};

  final sessions = <Map<String, dynamic>>[
    // ── Week 11 (~75 วันที่แล้ว) เพิ่งเริ่ม ยังไม่ชัวร์ ทำไม่ครบ ──
    s('Push Day', d(76, 19), [
      ex('flat_barbell_bench_press', 3, 8,  60.0),
      ex('dumbbell_shoulder_press',  3, 10, 18.0),
      ex('dumbbell_lateral_raise',   3, 12,  8.0),
      ex('cable_tricep_pushdown',    3, 12, 22.5),
      // ลืม incline
    ]),
    s('Leg Day', d(74, 18), [
      ex('barbell_squat',       3, 8,  70.0),
      ex('high_foot_leg_press', 3, 12, 100.0),
      ex('leg_curl',            3, 12, 35.0),
      ex('leg_extension',       3, 12, 32.5),
      // ข้าม calf raise
    ]),
    // ข้าม Pull วันนั้น

    // ── Week 10 ──
    s('Push Day', d(69, 20), [
      ex('flat_barbell_bench_press', 4, 6,  62.5),
      ex('incline_chest_press',      3, 10, 40.0),
      ex('dumbbell_shoulder_press',  3, 10, 20.0),
      ex('dumbbell_lateral_raise',   3, 12,  8.0),
      ex('cable_tricep_pushdown',    3, 12, 25.0),
    ]),
    s('Pull Day', d(67, 19), [
      ex('barbell_row',   4, 6,  55.0),
      ex('lat_pulldown',  3, 10, 47.5),
      ex('barbell_curl',  3, 12, 22.5),
      ex('face_pull',     3, 15, 17.5),
      // ข้าม seated_row วันนั้น
    ]),
    // ข้าม Legs (ขี้เกียจ)

    // ── Week 9 ──
    s('Push Day', d(62, 18), [
      ex('flat_barbell_bench_press', 4, 6,  65.0),
      ex('incline_chest_press',      3, 10, 42.5),
      ex('dumbbell_shoulder_press',  3, 10, 20.0),
      ex('dumbbell_lateral_raise',   4, 12, 10.0),
      ex('cable_tricep_pushdown',    3, 12, 27.5),
    ]),
    s('Pull Day', d(60, 19), [
      ex('barbell_row',   4, 6,  57.5),
      ex('lat_pulldown',  3, 10, 50.0),
      ex('seated_row',    3, 12, 45.0),
      ex('barbell_curl',  3, 10, 25.0),
      ex('face_pull',     3, 15, 20.0),
    ]),
    s('Leg Day', d(58, 17), [
      ex('barbell_squat',       4, 6,  72.5),
      ex('high_foot_leg_press', 3, 12, 110.0),
      ex('leg_curl',            3, 12, 37.5),
      ex('leg_extension',       3, 12, 37.5),
      ex('seated_calf_raise',   4, 15, 42.5),
    ]),

    // ── Week 8 (ป่วยนิดหน่อย ทำแค่ Push+Pull) ──
    s('Push Day', d(55, 20), [
      ex('flat_barbell_bench_press', 4, 5,  65.0), // ล้าหน่อย reps น้อยลง
      ex('incline_chest_press',      3, 10, 42.5),
      ex('dumbbell_shoulder_press',  3, 10, 22.0),
      ex('cable_tricep_pushdown',    3, 12, 27.5),
    ]),
    s('Pull Day', d(53, 19), [
      ex('barbell_row',   4, 6,  60.0),
      ex('lat_pulldown',  3, 10, 52.5),
      ex('seated_row',    3, 12, 47.5),
      ex('barbell_curl',  3, 10, 25.0),
      ex('face_pull',     3, 15, 20.0),
    ]),
    // Legs ป่วย ไม่ได้ทำ

    // ── Week 7 (ข้าม Push แต่ทำ Pull+Legs) ──
    s('Pull Day', d(46, 18), [
      ex('barbell_row',   4, 6,  60.0),
      ex('lat_pulldown',  3, 10, 55.0),
      ex('seated_row',    3, 12, 50.0),
      ex('barbell_curl',  4, 10, 27.5),
      ex('face_pull',     3, 15, 22.5),
    ]),
    s('Leg Day', d(44, 17), [
      ex('barbell_squat',       4, 5,  77.5), // PR attempt ไม่ค่อยสำเร็จ
      ex('high_foot_leg_press', 3, 10, 120.0),
      ex('leg_curl',            3, 12, 40.0),
      ex('leg_extension',       3, 12, 40.0),
      ex('seated_calf_raise',   4, 15, 45.0),
    ]),

    // ── Week 6 (กลับมาครบ มีพลัง) ──
    s('Push Day', d(41, 19), [
      ex('flat_barbell_bench_press', 4, 6,  67.5),
      ex('incline_chest_press',      3, 10, 45.0),
      ex('dumbbell_shoulder_press',  3, 10, 22.0),
      ex('dumbbell_lateral_raise',   4, 12, 10.0),
      ex('cable_tricep_pushdown',    3, 12, 30.0),
    ]),
    s('Pull Day', d(39, 18), [
      ex('barbell_row',   4, 6,  62.5),
      ex('lat_pulldown',  3, 10, 57.5),
      ex('seated_row',    3, 12, 50.0),
      ex('barbell_curl',  3, 10, 27.5),
      ex('face_pull',     3, 15, 22.5),
    ]),
    s('Leg Day', d(37, 17), [
      ex('barbell_squat',       4, 6,  80.0),
      ex('high_foot_leg_press', 4, 10, 120.0),
      ex('leg_curl',            3, 12, 42.5),
      ex('leg_extension',       3, 12, 42.5),
      ex('seated_calf_raise',   4, 15, 47.5),
    ]),

    // ── Week 5 (งานยุ่ง ข้าม Push) ──
    s('Pull Day', d(32, 20), [
      ex('barbell_row',   4, 6,  65.0),
      ex('lat_pulldown',  3, 10, 60.0),
      ex('seated_row',    3, 12, 52.5),
      ex('barbell_curl',  3, 10, 30.0),
      ex('face_pull',     3, 15, 22.5),
    ]),
    s('Leg Day', d(30, 18), [
      ex('barbell_squat',       4, 6,  82.5),
      ex('high_foot_leg_press', 4, 10, 125.0),
      ex('leg_curl',            3, 12, 42.5),
      ex('leg_extension',       4, 12, 42.5),
      ex('seated_calf_raise',   4, 15, 50.0),
    ]),

    // ── Week 4 (ครบทุกวัน จุดที่ดีที่สุด) ──
    s('Push Day', d(27, 19), [
      ex('flat_barbell_bench_press', 4, 6,  70.0),
      ex('incline_chest_press',      3, 10, 47.5),
      ex('dumbbell_shoulder_press',  3, 10, 24.0),
      ex('dumbbell_lateral_raise',   4, 12, 12.0),
      ex('cable_tricep_pushdown',    4, 12, 32.5),
    ]),
    s('Pull Day', d(25, 18), [
      ex('barbell_row',   4, 6,  67.5),
      ex('lat_pulldown',  3, 10, 62.5),
      ex('seated_row',    3, 12, 55.0),
      ex('barbell_curl',  4, 10, 30.0),
      ex('face_pull',     3, 15, 25.0),
    ]),
    s('Leg Day', d(23, 17), [
      ex('barbell_squat',       4, 6,  85.0),
      ex('high_foot_leg_press', 4, 10, 130.0),
      ex('leg_curl',            3, 12, 45.0),
      ex('leg_extension',       3, 12, 45.0),
      ex('seated_calf_raise',   4, 15, 52.5),
    ]),

    // ── Week 3 (Push+Pull ข้าม Legs วันศุกร์ไปดูหนัง) ──
    s('Push Day', d(20, 20), [
      ex('flat_barbell_bench_press', 4, 6,  72.5),
      ex('incline_chest_press',      3, 10, 50.0),
      ex('dumbbell_shoulder_press',  3, 10, 24.0),
      ex('dumbbell_lateral_raise',   4, 12, 12.0),
      ex('cable_tricep_pushdown',    4, 12, 35.0),
    ]),
    s('Pull Day', d(18, 19), [
      ex('barbell_row',   4, 6,  70.0),
      ex('lat_pulldown',  3, 10, 65.0),
      ex('seated_row',    3, 12, 57.5),
      ex('barbell_curl',  4, 10, 32.5),
      ex('face_pull',     3, 15, 25.0),
    ]),
    // Legs ไปดูหนัง

    // ── Week 2 (ครบ มีพลัง น้ำหนักขึ้น) ──
    s('Push Day', d(13, 19), [
      ex('flat_barbell_bench_press', 4, 6,  75.0),
      ex('incline_chest_press',      3, 10, 52.5),
      ex('dumbbell_shoulder_press',  4, 10, 26.0),
      ex('dumbbell_lateral_raise',   4, 12, 14.0),
      ex('cable_tricep_pushdown',    4, 12, 35.0),
    ]),
    s('Pull Day', d(11, 18), [
      ex('barbell_row',   4, 6,  72.5),
      ex('lat_pulldown',  3, 10, 67.5),
      ex('seated_row',    4, 12, 60.0),
      ex('barbell_curl',  4, 10, 32.5),
      ex('face_pull',     4, 15, 27.5),
    ]),
    s('Leg Day', d(9, 17), [
      ex('barbell_squat',       4, 6,  87.5),
      ex('high_foot_leg_press', 4, 10, 140.0),
      ex('leg_curl',            4, 12, 47.5),
      ex('leg_extension',       4, 12, 47.5),
      ex('seated_calf_raise',   4, 15, 55.0),
    ]),

    // ── Week 1 (ล่าสุด Push+Pull ยังไม่ถึงวัน Legs) ──
    s('Push Day', d(6, 19), [
      ex('flat_barbell_bench_press', 4, 6,  77.5),
      ex('incline_chest_press',      3, 10, 55.0),
      ex('dumbbell_shoulder_press',  4, 10, 26.0),
      ex('dumbbell_lateral_raise',   4, 12, 14.0),
      ex('cable_tricep_pushdown',    4, 12, 37.5),
    ]),
    s('Pull Day', d(4, 18), [
      ex('barbell_row',   4, 6,  75.0),
      ex('lat_pulldown',  4, 10, 70.0),
      ex('seated_row',    4, 12, 62.5),
      ex('barbell_curl',  4, 10, 35.0),
      ex('face_pull',     4, 15, 27.5),
    ]),
    // Legs ยังไม่ถึงวัน
  ];

  for (final session in sessions) {
    await db.collection('workout_history').add(session);
  }
  debugPrint('✅ Seeded ${sessions.length} realistic sessions for John (uid=$uid)');
  await auth.signOut();
}

// ═══════════════════════════════════════════════════════════
// 0. USERS — สร้าง Firebase Auth + Firestore document
//    email จะถูกสร้างในรูปแบบ {username}@gymbro.internal
// ═══════════════════════════════════════════════════════════

const _seedUsers = <Map<String, String>>[
  {
    'username': 'john123',
    'name': 'John Smith',
    'password': 'gymbro123',
    'image_url':
        'https://i.pravatar.cc/150?img=11',
  },
  {
    'username': 'jane456',
    'name': 'Jane Doe',
    'password': 'gymbro123',
    'image_url':
        'https://i.pravatar.cc/150?img=47',
  },
  {
    'username': 'mike789',
    'name': 'Mike Johnson',
    'password': 'gymbro123',
    'image_url':
        'https://i.pravatar.cc/150?img=68',
  },
];

Future<void> seedUsers(FirebaseFirestore db) async {
  final auth = FirebaseAuth.instance;

  for (final u in _seedUsers) {
    final email = '${u['username']}@gymbro.internal';
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: u['password']!,
      );
      await db.collection('users').doc(cred.user!.uid).set({
        'username': u['username'],
        'name': u['name'],
        'image_url': u['image_url'],
        'friends': <String>[],
        'active_program_id': null,
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint('Seeded user: ${u['username']}');
    } catch (e) {
      debugPrint('Skip ${u['username']}: $e');
    }
  }

  // ลง sign out หลัง seed เสร็จ (ไม่ให้ค้าง session ของ seed user)
  await auth.signOut();
  debugPrint('Seeded users (${_seedUsers.length})');
}

// ═══════════════════════════════════════════════════════════
// 1. MUSCLES (22 muscles from seed.go)
// ═══════════════════════════════════════════════════════════

Future<void> seedMuscles(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final m in _muscles) {
    batch.set(db.collection('muscles').doc(m['id'] as String), {
      'muscle_name': m['muscle_name'],
      'scientific_name': m['scientific_name'],
      'body_region': m['body_region'],
      'function': m['function'],
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  debugPrint('Seeded muscles (${_muscles.length})');
}

const _muscles = <Map<String, dynamic>>[
  // Chest
  {
    'id': 'pectoralis_major',
    'muscle_name': 'Pectoralis Major',
    'scientific_name': 'Pectoralis major',
    'body_region': 'chest',
    'function': 'Flexion, adduction, and medial rotation of the humerus',
  },
  {
    'id': 'pectoralis_minor',
    'muscle_name': 'Pectoralis Minor',
    'scientific_name': 'Pectoralis minor',
    'body_region': 'chest',
    'function': 'Stabilizes the scapula',
  },
  // Back
  {
    'id': 'latissimus_dorsi',
    'muscle_name': 'Latissimus Dorsi',
    'scientific_name': 'Latissimus dorsi',
    'body_region': 'back',
    'function': 'Extension, adduction, and medial rotation of the shoulder',
  },
  {
    'id': 'trapezius',
    'muscle_name': 'Trapezius',
    'scientific_name': 'Trapezius',
    'body_region': 'back',
    'function': 'Elevates, retracts, and rotates the scapula',
  },
  {
    'id': 'rhomboids',
    'muscle_name': 'Rhomboids',
    'scientific_name': 'Rhomboideus',
    'body_region': 'back',
    'function': 'Retracts and elevates the scapula',
  },
  {
    'id': 'erector_spinae',
    'muscle_name': 'Erector Spinae',
    'scientific_name': 'Erector spinae',
    'body_region': 'back',
    'function': 'Extends and laterally flexes the vertebral column',
  },
  // Shoulders
  {
    'id': 'anterior_deltoid',
    'muscle_name': 'Anterior Deltoid',
    'scientific_name': 'Deltoideus anterior',
    'body_region': 'shoulders',
    'function': 'Flexion and medial rotation of the arm',
  },
  {
    'id': 'lateral_deltoid',
    'muscle_name': 'Lateral Deltoid',
    'scientific_name': 'Deltoideus lateralis',
    'body_region': 'shoulders',
    'function': 'Abduction of the arm',
  },
  {
    'id': 'posterior_deltoid',
    'muscle_name': 'Posterior Deltoid',
    'scientific_name': 'Deltoideus posterior',
    'body_region': 'shoulders',
    'function': 'Extension and lateral rotation of the arm',
  },
  // Arms
  {
    'id': 'biceps_brachii',
    'muscle_name': 'Biceps Brachii',
    'scientific_name': 'Biceps brachii',
    'body_region': 'arms',
    'function': 'Flexion of the elbow and supination of the forearm',
  },
  {
    'id': 'triceps_brachii',
    'muscle_name': 'Triceps Brachii',
    'scientific_name': 'Triceps brachii',
    'body_region': 'arms',
    'function': 'Extension of the elbow',
  },
  {
    'id': 'brachialis',
    'muscle_name': 'Brachialis',
    'scientific_name': 'Brachialis',
    'body_region': 'arms',
    'function': 'Flexion of the elbow',
  },
  {
    'id': 'forearm_flexors',
    'muscle_name': 'Forearm Flexors',
    'scientific_name': 'Flexor group',
    'body_region': 'arms',
    'function': 'Flexion of the wrist and fingers',
  },
  {
    'id': 'forearm_extensors',
    'muscle_name': 'Forearm Extensors',
    'scientific_name': 'Extensor group',
    'body_region': 'arms',
    'function': 'Extension of the wrist and fingers',
  },
  // Legs
  {
    'id': 'quadriceps',
    'muscle_name': 'Quadriceps',
    'scientific_name': 'Quadriceps femoris',
    'body_region': 'legs',
    'function': 'Extension of the knee',
  },
  {
    'id': 'hamstrings',
    'muscle_name': 'Hamstrings',
    'scientific_name': 'Hamstring group',
    'body_region': 'legs',
    'function': 'Flexion of the knee and extension of the hip',
  },
  {
    'id': 'glutes',
    'muscle_name': 'Glutes',
    'scientific_name': 'Gluteus maximus',
    'body_region': 'legs',
    'function': 'Extension and lateral rotation of the hip',
  },
  {
    'id': 'calves',
    'muscle_name': 'Calves',
    'scientific_name': 'Gastrocnemius and Soleus',
    'body_region': 'legs',
    'function': 'Plantarflexion of the ankle',
  },
  {
    'id': 'adductors',
    'muscle_name': 'Adductors',
    'scientific_name': 'Adductor group',
    'body_region': 'legs',
    'function': 'Adduction of the hip',
  },
  // Core
  {
    'id': 'rectus_abdominis',
    'muscle_name': 'Rectus Abdominis',
    'scientific_name': 'Rectus abdominis',
    'body_region': 'core',
    'function': 'Flexion of the lumbar spine',
  },
  {
    'id': 'obliques',
    'muscle_name': 'Obliques',
    'scientific_name': 'Obliquus externus and internus',
    'body_region': 'core',
    'function': 'Rotation and lateral flexion of the trunk',
  },
  {
    'id': 'transverse_abdominis',
    'muscle_name': 'Transverse Abdominis',
    'scientific_name': 'Transversus abdominis',
    'body_region': 'core',
    'function': 'Compression of the abdominal contents',
  },
];

// ═══════════════════════════════════════════════════════════
// 2. MUSCLE GROUPS (with member muscle IDs embedded)
// ═══════════════════════════════════════════════════════════

Future<void> seedMuscleGroups(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final g in _muscleGroups) {
    batch.set(db.collection('muscle_groups').doc(g['id'] as String), {
      'group_name': g['group_name'],
      'split_category': g['split_category'],
      'muscle_ids': g['muscle_ids'],
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  debugPrint('Seeded muscle_groups (${_muscleGroups.length})');
}

const _muscleGroups = <Map<String, dynamic>>[
  {
    'id': 'chest',
    'group_name': 'Chest',
    'split_category': 'Push',
    'muscle_ids': ['pectoralis_major', 'pectoralis_minor'],
  },
  {
    'id': 'back',
    'group_name': 'Back',
    'split_category': 'Pull',
    'muscle_ids': [
      'latissimus_dorsi',
      'trapezius',
      'rhomboids',
      'erector_spinae',
    ],
  },
  {
    'id': 'shoulders',
    'group_name': 'Shoulders',
    'split_category': 'Push',
    'muscle_ids': ['anterior_deltoid', 'lateral_deltoid', 'posterior_deltoid'],
  },
  {
    'id': 'arms',
    'group_name': 'Arms',
    'split_category': 'Push',
    'muscle_ids': [
      'biceps_brachii',
      'triceps_brachii',
      'brachialis',
      'forearm_flexors',
      'forearm_extensors',
    ],
  },
  {
    'id': 'legs',
    'group_name': 'Legs',
    'split_category': 'Legs',
    'muscle_ids': ['quadriceps', 'hamstrings', 'glutes', 'calves', 'adductors'],
  },
  {
    'id': 'core',
    'group_name': 'Core',
    'split_category': 'Upper',
    'muscle_ids': ['rectus_abdominis', 'obliques', 'transverse_abdominis'],
  },
];

// ═══════════════════════════════════════════════════════════
// 3. MACHINES (17 items from seed.go)
// ═══════════════════════════════════════════════════════════

Future<void> seedMachines(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final m in _machines) {
    batch.set(db.collection('machines').doc(m['id'] as String), {
      'equipment_name': m['equipment_name'],
      'equipment_type': m['equipment_type'],
      'description': m['description'],
      'status': m['status'],
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  debugPrint('Seeded machines (${_machines.length})');
}

const _machines = <Map<String, dynamic>>[
  {
    'id': 'aerobic_fitness_area_gym',
    'equipment_name': 'Aerobic fitness area gym',
    'equipment_type': 'area',
    'description': 'พื้นที่โล่งสำหรับแอโรบิกและออกกำลังกายเป็นกลุ่ม',
    'status': 'ACTIVE',
  },
  {
    'id': 'assisted_pull_up_machine',
    'equipment_name': 'Assisted Pull Up Machine',
    'equipment_type': 'machine',
    'description': 'เครื่องช่วย pull-up และ dip แบบถ่วงน้ำหนัก',
    'status': 'ACTIVE',
  },
  {
    'id': 'barbell_rack',
    'equipment_name': 'Barbell Rack',
    'equipment_type': 'free_weight',
    'description': 'ชั้นวาง barbell และแผ่นน้ำหนัก',
    'status': 'ACTIVE',
  },
  {
    'id': 'bench',
    'equipment_name': 'Bench',
    'equipment_type': 'free_weight',
    'description': 'ม้านั่งปรับองศาได้สำหรับท่า free weight',
    'status': 'ACTIVE',
  },
  {
    'id': 'cable_chest_fly',
    'equipment_name': 'Cable Chest Fly',
    'equipment_type': 'cable',
    'description': 'สถานี cable สำหรับท่า chest fly',
    'status': 'ACTIVE',
  },
  {
    'id': 'cable_crossover_machine',
    'equipment_name': 'Cable Crossover Machine',
    'equipment_type': 'cable',
    'description': 'เครื่อง cable คู่สำหรับท่า chest fly และ crossover',
    'status': 'ACTIVE',
  },
  {
    'id': 'captain_chair_abs_station',
    'equipment_name': 'Captain Chair Abs Station',
    'equipment_type': 'bodyweight',
    'description': 'เก้าอี้ captain สำหรับท่า hanging leg raise และ knee tuck',
    'status': 'ACTIVE',
  },
  {
    'id': 'cardio_zone_gym',
    'equipment_name': 'Cardio zone gym',
    'equipment_type': 'area',
    'description': 'โซนเฉพาะสำหรับอุปกรณ์คาร์ดิโอ',
    'status': 'ACTIVE',
  },
  {
    'id': 'chest_press_machine',
    'equipment_name': 'Chest Press Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง chest press แบบใช้แผ่นหรือ selectorized',
    'status': 'ACTIVE',
  },
  {
    'id': 'curve_treadmill',
    'equipment_name': 'Curve Treadmill',
    'equipment_type': 'machine',
    'description': 'ลู่วิ่งโค้งแบบแมนนวล',
    'status': 'ACTIVE',
  },
  {
    'id': 'dual_lat_machine',
    'equipment_name': 'Dual Lat Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง lat pulldown อิสระสองแขน',
    'status': 'ACTIVE',
  },
  {
    'id': 'dumbbell_rack',
    'equipment_name': 'Dumbbell Rack',
    'equipment_type': 'free_weight',
    'description': 'ชั้นวาง dumbbell',
    'status': 'ACTIVE',
  },
  {
    'id': 'ez_curl_bar_rack',
    'equipment_name': 'EZ Curl Bar Rack',
    'equipment_type': 'free_weight',
    'description': 'ชั้นวาง EZ curl bar',
    'status': 'ACTIVE',
  },
  {
    'id': 'flat_barbell_bench_press_station',
    'equipment_name': 'Flat Barbell Bench Press Station',
    'equipment_type': 'machine',
    'description': 'สถานี bench press แนวราบ',
    'status': 'ACTIVE',
  },
  {
    'id': 'gym_locker',
    'equipment_name': 'Gym locker',
    'equipment_type': 'facility',
    'description': 'ตู้ล็อกเกอร์สำหรับเก็บของสมาชิก',
    'status': 'ACTIVE',
  },
  {
    'id': 'gym_reception_counter',
    'equipment_name': 'Gym reception counter',
    'equipment_type': 'facility',
    'description': 'เคาน์เตอร์ต้อนรับส่วนหน้าของฟิตเนส',
    'status': 'ACTIVE',
  },
  {
    'id': 'gym_vending_machine',
    'equipment_name': 'Gym vending machine',
    'equipment_type': 'facility',
    'description': 'ตู้ขายของอัตโนมัติสำหรับอาหารและอาหารเสริม',
    'status': 'ACTIVE',
  },
  {
    'id': 'hip_abductor_machine',
    'equipment_name': 'Hip Abductor Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate กล้ามเนื้อกางสะโพก',
    'status': 'ACTIVE',
  },
  {
    'id': 'hip_adductor_machine',
    'equipment_name': 'Hip Adductor Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate กล้ามเนื้อหุบสะโพก',
    'status': 'ACTIVE',
  },
  {
    'id': 'incline_barbell_bench_press_station',
    'equipment_name': 'Incline Barbell Bench Press Station',
    'equipment_type': 'machine',
    'description': 'สถานี bench press แบบเอียงขึ้น',
    'status': 'ACTIVE',
  },
  {
    'id': 'incline_chest_press_machine',
    'equipment_name': 'Incline Chest Press Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง chest press แบบเอียงเน้นหน้าอกบน',
    'status': 'ACTIVE',
  },
  {
    'id': 'lat_pull',
    'equipment_name': 'Lat Pull',
    'equipment_type': 'machine',
    'description': 'เครื่อง lat pull สำหรับการดึงแนวตั้ง',
    'status': 'ACTIVE',
  },
  {
    'id': 'lat_pulldown_machine',
    'equipment_name': 'Lat Pulldown Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง cable สำหรับท่า lat pulldown',
    'status': 'ACTIVE',
  },
  {
    'id': 'lateral_raise_machine',
    'equipment_name': 'Lateral Raise Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate การกางไหล่ด้านข้าง',
    'status': 'ACTIVE',
  },
  {
    'id': 'leg_curl_machine',
    'equipment_name': 'Leg Curl Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate กล้ามเนื้อ hamstring',
    'status': 'ACTIVE',
  },
  {
    'id': 'leg_extension_machine',
    'equipment_name': 'Leg Extension Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate กล้ามเนื้อ quadriceps',
    'status': 'ACTIVE',
  },
  {
    'id': 'lying_leg_curl_machine',
    'equipment_name': 'Lying Leg Curl Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง leg curl แบบนอนคว่ำ',
    'status': 'ACTIVE',
  },
  {
    'id': 'olympic_lifting_platform',
    'equipment_name': 'Olympic Lifting Platform',
    'equipment_type': 'free_weight',
    'description': 'แพลตฟอร์มสำหรับ Olympic lifting',
    'status': 'ACTIVE',
  },
  {
    'id': 'pec_deck_fly',
    'equipment_name': 'Pec Deck Fly',
    'equipment_type': 'machine',
    'description': 'เครื่อง pec deck สำหรับ isolate หน้าอก',
    'status': 'ACTIVE',
  },
  {
    'id': 'preacher_curl_machine',
    'equipment_name': 'Preacher Curl Machine',
    'equipment_type': 'machine',
    'description': 'เครื่องสำหรับท่า preacher curl',
    'status': 'ACTIVE',
  },
  {
    'id': 'roman_chair',
    'equipment_name': 'Roman Chair',
    'equipment_type': 'bodyweight',
    'description': 'Roman chair สำหรับท่า back extension และ core',
    'status': 'ACTIVE',
  },
  {
    'id': 'row_machine',
    'equipment_name': 'Row Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง rowing สำหรับกล้ามเนื้อหลัง',
    'status': 'ACTIVE',
  },
  {
    'id': 'rowing_machine',
    'equipment_name': 'Rowing Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง rowing ในร่มสำหรับคาร์ดิโอ',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_cable_row',
    'equipment_name': 'Seated Cable Row',
    'equipment_type': 'cable',
    'description': 'สถานี cable row แบบนั่งสำหรับดึงแนวนอน',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_calf_press_machine',
    'equipment_name': 'Seated Calf Press Machine',
    'equipment_type': 'machine',
    'description': 'เครื่องนั่งสำหรับท่า calf raise',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_crunch_machine',
    'equipment_name': 'Seated Crunch Machine',
    'equipment_type': 'machine',
    'description': 'เครื่องนั่ง isolate กล้ามเนื้อท้อง',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_leg_curl_machine',
    'equipment_name': 'Seated Leg Curl Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง leg curl แบบนั่งสำหรับ hamstrings',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_leg_press_machine',
    'equipment_name': 'Seated Leg Press Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง leg press แบบนั่งแนวนอน',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_row_machine',
    'equipment_name': 'Seated Row Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง cable row แบบนั่งสำหรับความหนาของหลัง',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_shoulder_press',
    'equipment_name': 'Seated Shoulder Press',
    'equipment_type': 'machine',
    'description': 'สถานี shoulder press แบบนั่ง',
    'status': 'ACTIVE',
  },
  {
    'id': 'seated_triceps_press',
    'equipment_name': 'Seated Triceps Press',
    'equipment_type': 'machine',
    'description': 'เครื่องนั่งสำหรับท่า triceps press',
    'status': 'ACTIVE',
  },
  {
    'id': 'shoulder_press_machine',
    'equipment_name': 'Shoulder Press Machine',
    'equipment_type': 'machine',
    'description': 'เครื่องสำหรับท่า overhead shoulder press',
    'status': 'ACTIVE',
  },
  {
    'id': 'smith_machine',
    'equipment_name': 'Smith Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง barbell แบบราง fixed สำหรับท่าต่างๆ',
    'status': 'ACTIVE',
  },
  {
    'id': 'squat_rack',
    'equipment_name': 'Squat Rack',
    'equipment_type': 'machine',
    'description': 'Power rack สำหรับ squat และ press',
    'status': 'ACTIVE',
  },
  {
    'id': 'standing_leg_curl_machine',
    'equipment_name': 'Standing Leg Curl Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง leg curl ขาเดียวแบบยืน',
    'status': 'ACTIVE',
  },
  {
    'id': 'tricep_extension_machine',
    'equipment_name': 'Tricep Extension Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง isolate tricep extension',
    'status': 'ACTIVE',
  },
  {
    'id': 'v_squat_machine',
    'equipment_name': 'V Squat Machine',
    'equipment_type': 'machine',
    'description': 'เครื่อง V-squat เน้น quad',
    'status': 'ACTIVE',
  },
];

// ═══════════════════════════════════════════════════════════
// 4. EXERCISES (28 exercises, with muscle & machine embedded)
// ═══════════════════════════════════════════════════════════


Future<void> seedExercises(FirebaseFirestore db) async {
  final batch = db.batch();
  for (final e in _exercises) {
    batch.set(db.collection('exercises').doc(e['id'] as String), {
      'exercise_name': e['name'],
      'movement_type': e['movement_type'],
      'movement_pattern': e['movement_pattern'],
      'description': e['description'],
      'difficulty_level': e['difficulty_level'],
      'is_compound': e['is_compound'],
      'muscle_involvements': e['muscles'],
      'equipment': e['equipment'],
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  debugPrint('Seeded exercises (${_exercises.length})');
}

const _exercises = <Map<String, dynamic>>[
  {
    'id': 'flat_barbell_bench_press',
    'name': 'Flat Barbell Bench Press',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal push',
    'description': 'เบนช์เพรสท่าราบด้วยบาร์เบล',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 70},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Flat Barbell Bench Press Station', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'incline_barbell_bench_press',
    'name': 'Incline Barbell Bench Press',
    'movement_type': 'compound',
    'movement_pattern': 'incline push',
    'description': 'เบนช์เพรสแบบลาดเอียงเน้นอกส่วนบน',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 50},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Incline Barbell Bench Press Station', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'machine_chest_press',
    'name': 'Machine Chest Press',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal push',
    'description': 'เครื่องเพรสอก เหมาะสำหรับผู้เริ่มต้น',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 70},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Chest Press Machine', 'is_required': true}
    ],
  },
  {
    'id': 'incline_machine_chest_press',
    'name': 'Incline Machine Chest Press',
    'movement_type': 'compound',
    'movement_pattern': 'incline push',
    'description': 'เครื่องเพรสลาดเอียงสำหรับอกส่วนบน',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 55},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Incline Chest Press Machine', 'is_required': true}
    ],
  },
  {
    'id': 'pec_deck_fly',
    'name': 'Pec Deck Fly',
    'movement_type': 'isolation',
    'movement_pattern': 'chest fly',
    'description': 'เครื่องบินอกสำหรับแยกกล้ามอกชั้นใน',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Pectoralis Minor', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Pec Deck Fly', 'is_required': true}
    ],
  },
  {
    'id': 'cable_crossover',
    'name': 'Cable Crossover',
    'movement_type': 'isolation',
    'movement_pattern': 'chest fly',
    'description': 'เคเบิลครอสโอเวอร์สำหรับยืดและหดอกเต็มช่วง',
    'difficulty_level': 'intermediate',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Cable Crossover Machine', 'is_required': true}
    ],
  },
  {
    'id': 'cable_chest_fly',
    'name': 'Cable Chest Fly',
    'movement_type': 'isolation',
    'movement_pattern': 'chest fly',
    'description': 'เคเบิลฟลายแยกกล้ามอก',
    'difficulty_level': 'intermediate',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Cable Chest Fly', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_bench_press',
    'name': 'Dumbbell Bench Press',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal push',
    'description': 'ดัมเบลเพรสราบเพิ่มช่วงการเคลื่อนไหวของอก',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 65},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Bench', 'is_required': true},
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_fly',
    'name': 'Dumbbell Fly',
    'movement_type': 'isolation',
    'movement_pattern': 'chest fly',
    'description': 'ดัมเบลฟลายยืดและแยกกล้ามอก',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Bench', 'is_required': true},
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'smith_machine_bench_press',
    'name': 'Smith Machine Bench Press',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal push',
    'description': 'เบนช์เพรสบาร์เบลบน Smith Machine',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'primary', 'activation_percentage': 65},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Smith Machine', 'is_required': true}
    ],
  },
  {
    'id': 'lat_pulldown',
    'name': 'Lat Pulldown',
    'movement_type': 'compound',
    'movement_pattern': 'vertical pull',
    'description': 'แลทพูลดาวน์ขยายความกว้างของหลัง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 60},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Lat Pulldown Machine', 'is_required': true}
    ],
  },
  {
    'id': 'lat_pull',
    'name': 'Lat Pull',
    'movement_type': 'compound',
    'movement_pattern': 'vertical pull',
    'description': 'เครื่องแลทพูลฝึกความแข็งแกร่งการดึงแนวดิ่ง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 60},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Lat Pull', 'is_required': true}
    ],
  },
  {
    'id': 'dual_lat_pulldown',
    'name': 'Dual Lat Pulldown',
    'movement_type': 'compound',
    'movement_pattern': 'vertical pull',
    'description': 'แลทพูลดาวน์สองมือแยกอิสระเพื่อความสมมาตร',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 60},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Dual Lat Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_cable_row',
    'name': 'Seated Cable Row',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal pull',
    'description': 'โรว์เคเบิลนั่งเพิ่มความหนาของหลัง',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 40},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Seated Cable Row', 'is_required': true}
    ],
  },
  {
    'id': 'machine_row',
    'name': 'Machine Row',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal pull',
    'description': 'เครื่องโรว์แบบแผ่นน้ำหนักหรือเลือกน้ำหนักได้',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 40},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Row Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_row',
    'name': 'Seated Row',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal pull',
    'description': 'เครื่องโรว์นั่งพัฒนากล้ามหลัง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 40},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Seated Row Machine', 'is_required': true}
    ],
  },
  {
    'id': 'assisted_pull_up',
    'name': 'Assisted Pull-up',
    'movement_type': 'compound',
    'movement_pattern': 'vertical pull',
    'description': 'พูลอัพช่วยน้ำหนัก เหมาะสำหรับผู้เริ่มต้นสร้างความแข็งแกร่งของหลัง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 55},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 25}
    ],
    'equipment': [
      {'equipment_name': 'Assisted Pull Up Machine', 'is_required': true}
    ],
  },
  {
    'id': 'barbell_row',
    'name': 'Barbell Row',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal pull',
    'description': 'บาร์เบลโรว์โน้มตัวเพิ่มความหนาของหลัง',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 40},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_row',
    'name': 'Dumbbell Row',
    'movement_type': 'compound',
    'movement_pattern': 'horizontal pull',
    'description': 'ดัมเบลโรว์มือเดียวพัฒนากล้ามหลังแต่ละข้าง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 50},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'secondary', 'activation_percentage': 30},
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true},
      {'equipment_name': 'Bench', 'is_required': false}
    ],
  },
  {
    'id': 'back_extension',
    'name': 'Back Extension',
    'movement_type': 'isolation',
    'movement_pattern': 'spinal extension',
    'description': 'แบ็คเอ็กซ์เทนชันบน Roman Chair เสริมหลังล่างและก้น',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Glutes', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Roman Chair', 'is_required': true}
    ],
  },
  {
    'id': 'machine_overhead_press',
    'name': 'Machine Overhead Press',
    'movement_type': 'compound',
    'movement_pattern': 'vertical push',
    'description': 'เครื่องเพรสไหล่แบบนำทาง',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 45},
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 25}
    ],
    'equipment': [
      {'equipment_name': 'Shoulder Press Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_machine_shoulder_press',
    'name': 'Seated Machine Shoulder Press',
    'movement_type': 'compound',
    'movement_pattern': 'vertical push',
    'description': 'เครื่องเพรสไหล่นั่งควบคุมการยกเหนือศีรษะ',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 45},
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 25}
    ],
    'equipment': [
      {'equipment_name': 'Seated Shoulder Press', 'is_required': true}
    ],
  },
  {
    'id': 'machine_lateral_raise',
    'name': 'Machine Lateral Raise',
    'movement_type': 'isolation',
    'movement_pattern': 'shoulder abduction',
    'description': 'เครื่องยกข้างแยกกล้ามเดลทอยด์ด้านข้าง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Lateral Raise Machine', 'is_required': true}
    ],
  },
  {
    'id': 'barbell_overhead_press',
    'name': 'Barbell Overhead Press',
    'movement_type': 'compound',
    'movement_pattern': 'vertical push',
    'description': 'บาร์เบลเพรสยืนเสริมความแข็งแกร่งไหล่และลำตัวบน',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 45},
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Trapezius', 'involvement_type': 'stabilizer', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Squat Rack', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_shoulder_press',
    'name': 'Dumbbell Shoulder Press',
    'movement_type': 'compound',
    'movement_pattern': 'vertical push',
    'description': 'ดัมเบลเพรสไหล่แบบนั่งหรือยืน',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 40},
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'secondary', 'activation_percentage': 30}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_lateral_raise',
    'name': 'Dumbbell Lateral Raise',
    'movement_type': 'isolation',
    'movement_pattern': 'shoulder abduction',
    'description': 'ดัมเบลยกข้างเพิ่มความกว้างไหล่',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_front_raise',
    'name': 'Dumbbell Front Raise',
    'movement_type': 'isolation',
    'movement_pattern': 'shoulder flexion',
    'description': 'ดัมเบลยกหน้าเน้นกล้ามเดลทอยด์ด้านหน้า',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Lateral Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'preacher_curl',
    'name': 'Preacher Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow flexion',
    'description': 'เครื่อง Preacher Curl เน้นการหดตัวสูงสุดของไบเซ็ป',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Brachialis', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Preacher Curl Machine', 'is_required': true}
    ],
  },
  {
    'id': 'cable_bicep_curl',
    'name': 'Cable Bicep Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow flexion',
    'description': 'เคเบิลเคิร์ลออกแรงคงที่ต่อไบเซ็ป',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Brachialis', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Cable Crossover Machine', 'is_required': true}
    ],
  },
  {
    'id': 'ez_bar_curl',
    'name': 'EZ Bar Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow flexion',
    'description': 'เคิร์ลด้วย EZ Bar ลดแรงกดที่ข้อมือ',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 75},
      {'muscle_name': 'Brachialis', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Forearm Flexors', 'involvement_type': 'stabilizer', 'activation_percentage': 5}
    ],
    'equipment': [
      {'equipment_name': 'EZ Curl Bar Rack', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_curl',
    'name': 'Dumbbell Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow flexion',
    'description': 'ดัมเบลเคิร์ลพัฒนาไบเซ็ปแต่ละข้าง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Brachialis', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Forearm Flexors', 'involvement_type': 'stabilizer', 'activation_percentage': 5}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'barbell_curl',
    'name': 'Barbell Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow flexion',
    'description': 'บาร์เบลเคิร์ลเพิ่มมวลไบเซ็ปทั้งสองข้าง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Biceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Brachialis', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Forearm Flexors', 'involvement_type': 'stabilizer', 'activation_percentage': 5}
    ],
    'equipment': [
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'machine_tricep_extension',
    'name': 'Machine Tricep Extension',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow extension',
    'description': 'เครื่องเอ็กซ์เทนชันไทรเซ็ปแบบนำทาง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Forearm Extensors', 'involvement_type': 'stabilizer', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Tricep Extension Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_triceps_press',
    'name': 'Seated Triceps Press',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow extension',
    'description': 'เครื่องเพรสไทรเซ็ปนั่งเน้นการยืดเหนือศีรษะ',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Forearm Extensors', 'involvement_type': 'stabilizer', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Seated Triceps Press', 'is_required': true}
    ],
  },
  {
    'id': 'cable_tricep_pushdown',
    'name': 'Cable Tricep Pushdown',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow extension',
    'description': 'เคเบิลพุชดาวน์แยกกล้ามไทรเซ็ปด้วยแรงคงที่',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Forearm Extensors', 'involvement_type': 'stabilizer', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Cable Crossover Machine', 'is_required': true}
    ],
  },
  {
    'id': 'assisted_dip',
    'name': 'Assisted Dip',
    'movement_type': 'compound',
    'movement_pattern': 'vertical push',
    'description': 'ดิปช่วยน้ำหนักพัฒนาไทรเซ็ปและอก',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 55},
      {'muscle_name': 'Pectoralis Major', 'involvement_type': 'secondary', 'activation_percentage': 25},
      {'muscle_name': 'Anterior Deltoid', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Assisted Pull Up Machine', 'is_required': true}
    ],
  },
  {
    'id': 'skull_crusher',
    'name': 'Skull Crusher',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow extension',
    'description': 'Skull Crusher ด้วย EZ Bar เพิ่มมวลไทรเซ็ป',
    'difficulty_level': 'intermediate',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Forearm Extensors', 'involvement_type': 'stabilizer', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'EZ Curl Bar Rack', 'is_required': true},
      {'equipment_name': 'Bench', 'is_required': true}
    ],
  },
  {
    'id': 'dumbbell_tricep_kickback',
    'name': 'Dumbbell Tricep Kickback',
    'movement_type': 'isolation',
    'movement_pattern': 'elbow extension',
    'description': 'ดัมเบลคิกแบ็กเน้นการหดตัวสูงสุดของไทรเซ็ป',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Triceps Brachii', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Forearm Extensors', 'involvement_type': 'stabilizer', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Dumbbell Rack', 'is_required': true},
      {'equipment_name': 'Bench', 'is_required': false}
    ],
  },
  {
    'id': 'barbell_squat',
    'name': 'Barbell Squat',
    'movement_type': 'compound',
    'movement_pattern': 'squat',
    'description': 'สควอตบาร์เบลท่าพื้นฐานเสริมความแข็งแกร่งขาและลำตัวล่าง',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 45},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 35},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'stabilizer', 'activation_percentage': 5}
    ],
    'equipment': [
      {'equipment_name': 'Squat Rack', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'smith_machine_squat',
    'name': 'Smith Machine Squat',
    'movement_type': 'compound',
    'movement_pattern': 'squat',
    'description': 'สควอตบน Smith Machine ควบคุมการเคลื่อนไหวได้ดี',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 50},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Smith Machine', 'is_required': true}
    ],
  },
  {
    'id': 'leg_press',
    'name': 'Leg Press',
    'movement_type': 'compound',
    'movement_pattern': 'squat',
    'description': 'เลกเพรสนั่งพัฒนาต้นขาและก้น',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 55},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Seated Leg Press Machine', 'is_required': true}
    ],
  },
  {
    'id': 'v_squat',
    'name': 'V Squat',
    'movement_type': 'compound',
    'movement_pattern': 'squat',
    'description': 'เครื่อง V Squat เน้นกล้ามต้นขาด้านหน้า',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 60},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'V Squat Machine', 'is_required': true}
    ],
  },
  {
    'id': 'leg_extension',
    'name': 'Leg Extension',
    'movement_type': 'isolation',
    'movement_pattern': 'knee extension',
    'description': 'เครื่องเลกเอ็กซ์เทนชันแยกกล้ามต้นขาด้านหน้า',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 100}
    ],
    'equipment': [
      {'equipment_name': 'Leg Extension Machine', 'is_required': true}
    ],
  },
  {
    'id': 'leg_curl',
    'name': 'Leg Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'knee flexion',
    'description': 'เครื่องเลกเคิร์ลแยกกล้ามต้นขาด้านหลัง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Calves', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Leg Curl Machine', 'is_required': true}
    ],
  },
  {
    'id': 'lying_leg_curl',
    'name': 'Lying Leg Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'knee flexion',
    'description': 'เลกเคิร์ลนอนคว่ำเน้นกล้ามต้นขาด้านหลัง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Calves', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Lying Leg Curl Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_leg_curl',
    'name': 'Seated Leg Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'knee flexion',
    'description': 'เลกเคิร์ลนั่งเน้นกล้ามต้นขาด้านหลัง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Calves', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Seated Leg Curl Machine', 'is_required': true}
    ],
  },
  {
    'id': 'standing_leg_curl',
    'name': 'Standing Leg Curl',
    'movement_type': 'isolation',
    'movement_pattern': 'knee flexion',
    'description': 'เลกเคิร์ลยืนขาเดียวฝึกแต่ละข้างแยกกัน',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Calves', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Standing Leg Curl Machine', 'is_required': true}
    ],
  },
  {
    'id': 'hip_abduction',
    'name': 'Hip Abduction',
    'movement_type': 'isolation',
    'movement_pattern': 'hip abduction',
    'description': 'เครื่องอะบักชันสะโพกแยกกล้ามก้นและสะโพกด้านนอก',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Adductors', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Hip Abductor Machine', 'is_required': true}
    ],
  },
  {
    'id': 'hip_adduction',
    'name': 'Hip Adduction',
    'movement_type': 'isolation',
    'movement_pattern': 'hip adduction',
    'description': 'เครื่องแอดดักชันสะโพกแยกกล้ามต้นขาด้านใน',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Adductors', 'involvement_type': 'primary', 'activation_percentage': 90},
      {'muscle_name': 'Glutes', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Hip Adductor Machine', 'is_required': true}
    ],
  },
  {
    'id': 'seated_calf_raise',
    'name': 'Seated Calf Raise',
    'movement_type': 'isolation',
    'movement_pattern': 'plantar flexion',
    'description': 'เคาฟเรซนั่งเน้นกล้ามโซเลอุส',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Calves', 'involvement_type': 'primary', 'activation_percentage': 100}
    ],
    'equipment': [
      {'equipment_name': 'Seated Calf Press Machine', 'is_required': true}
    ],
  },
  {
    'id': 'deadlift',
    'name': 'Deadlift',
    'movement_type': 'compound',
    'movement_pattern': 'hip hinge',
    'description': 'เดดลิฟต์บาร์เบลท่าคลาสสิกเสริมกล้ามด้านหลังทั้งหมด',
    'difficulty_level': 'advanced',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Barbell Rack', 'is_required': true},
      {'equipment_name': 'Olympic Lifting Platform', 'is_required': false}
    ],
  },
  {
    'id': 'romanian_deadlift',
    'name': 'Romanian Deadlift',
    'movement_type': 'compound',
    'movement_pattern': 'hip hinge',
    'description': 'RDL เน้น hamstrings และ glutes โดยเหยียดหลังตรงตลอด',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 50},
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'secondary', 'activation_percentage': 20},
    ],
    'equipment': [
      {'equipment_name': 'Barbell Rack', 'is_required': true},
    ],
  },
  {
    'id': 'power_clean',
    'name': 'Power Clean',
    'movement_type': 'compound',
    'movement_pattern': 'olympic lift',
    'description': 'เพาเวอร์คลีนบาร์เบลระเบิดพลังทั้งร่างกาย',
    'difficulty_level': 'advanced',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 15},
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Olympic Lifting Platform', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'snatch',
    'name': 'Snatch',
    'movement_type': 'compound',
    'movement_pattern': 'olympic lift',
    'description': 'สแนชแบบโอลิมปิกพัฒนาความแข็งแกร่งระเบิดทั้งร่าง',
    'difficulty_level': 'advanced',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Glutes', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Trapezius', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'secondary', 'activation_percentage': 10}
    ],
    'equipment': [
      {'equipment_name': 'Olympic Lifting Platform', 'is_required': true},
      {'equipment_name': 'Barbell Rack', 'is_required': true}
    ],
  },
  {
    'id': 'hanging_leg_raise',
    'name': 'Hanging Leg Raise',
    'movement_type': 'isolation',
    'movement_pattern': 'hip flexion',
    'description': 'ยกขาค้างบน Captain Chair เสริมกล้ามท้องส่วนล่าง',
    'difficulty_level': 'intermediate',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Rectus Abdominis', 'involvement_type': 'primary', 'activation_percentage': 55},
      {'muscle_name': 'Transverse Abdominis', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Obliques', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Captain Chair Abs Station', 'is_required': true}
    ],
  },
  {
    'id': 'knee_tuck',
    'name': 'Knee Tuck',
    'movement_type': 'isolation',
    'movement_pattern': 'hip flexion',
    'description': 'ดึงเข่าบน Captain Chair ฝึก Core สำหรับผู้เริ่มต้น',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Rectus Abdominis', 'involvement_type': 'primary', 'activation_percentage': 60},
      {'muscle_name': 'Transverse Abdominis', 'involvement_type': 'secondary', 'activation_percentage': 25},
      {'muscle_name': 'Obliques', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Captain Chair Abs Station', 'is_required': true}
    ],
  },
  {
    'id': 'machine_crunch',
    'name': 'Machine Crunch',
    'movement_type': 'isolation',
    'movement_pattern': 'trunk flexion',
    'description': 'เครื่องครันช์นั่งแยกกล้ามท้อง',
    'difficulty_level': 'beginner',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Rectus Abdominis', 'involvement_type': 'primary', 'activation_percentage': 85},
      {'muscle_name': 'Obliques', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Seated Crunch Machine', 'is_required': true}
    ],
  },
  {
    'id': 'roman_chair_sit_up',
    'name': 'Roman Chair Sit-up',
    'movement_type': 'isolation',
    'movement_pattern': 'trunk flexion',
    'description': 'ซิทอัปบน Roman Chair ในช่วงการเคลื่อนไหวเต็ม',
    'difficulty_level': 'intermediate',
    'is_compound': false,
    'muscles': [
      {'muscle_name': 'Rectus Abdominis', 'involvement_type': 'primary', 'activation_percentage': 80},
      {'muscle_name': 'Obliques', 'involvement_type': 'secondary', 'activation_percentage': 20}
    ],
    'equipment': [
      {'equipment_name': 'Roman Chair', 'is_required': true}
    ],
  },
  {
    'id': 'manual_treadmill_run',
    'name': 'Manual Treadmill Run',
    'movement_type': 'compound',
    'movement_pattern': 'cardio',
    'description': 'วิ่งบนลู่วิ่งเคิร์ฟแบบแมนวลสำหรับคาร์ดิโอความเข้มสูง',
    'difficulty_level': 'intermediate',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Quadriceps', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'primary', 'activation_percentage': 30},
      {'muscle_name': 'Calves', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Glutes', 'involvement_type': 'secondary', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Curve Treadmill', 'is_required': true}
    ],
  },
  {
    'id': 'rowing',
    'name': 'Rowing',
    'movement_type': 'compound',
    'movement_pattern': 'cardio',
    'description': 'พายเรือในร่มฝึกคาร์ดิโอและความอดทนทั้งร่างกาย',
    'difficulty_level': 'beginner',
    'is_compound': true,
    'muscles': [
      {'muscle_name': 'Latissimus Dorsi', 'involvement_type': 'primary', 'activation_percentage': 25},
      {'muscle_name': 'Rhomboids', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Quadriceps', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Hamstrings', 'involvement_type': 'secondary', 'activation_percentage': 20},
      {'muscle_name': 'Erector Spinae', 'involvement_type': 'stabilizer', 'activation_percentage': 15}
    ],
    'equipment': [
      {'equipment_name': 'Rowing Machine', 'is_required': true}
    ],
  }
];

// ═══════════════════════════════════════════════════════════
// 5. PROGRAMS (with sessions & session exercises embedded)
// ═══════════════════════════════════════════════════════════

Future<void> seedPrograms(FirebaseFirestore db) async {
  // Program 1: Push Pull Legs Split
  final pplRef = db.collection('programs').doc('push_pull_legs');
  await pplRef.set({
    'program_name': 'Push Pull Legs Split',
    'goal': 'muscle_gain',
    'duration_weeks': 12,
    'days_per_week': 6,
    'difficulty_level': 'intermediate',
    'description': '6-day split focusing on muscle hypertrophy',
    'created_at': FieldValue.serverTimestamp(),
  });

  // PPL Sessions (as subcollection)
  final pplSessions = pplRef.collection('sessions');

  await pplSessions.doc('push_day_a').set({
    'session_name': 'Push Day A',
    'workout_split': 'Push',
    'day_number': 1,
    'notes': 'Focus on chest and shoulders',
    'exercises': [
      {
        'exercise_id': 'flat_barbell_bench_press',
        'sets': 4,
        'reps': 8,
        'weight': 185.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'incline_barbell_bench_press',
        'sets': 3,
        'reps': 10,
        'weight': 135.0,
        'rest_seconds': 120,
        'order': 2,
      },
      {
        'exercise_id': 'barbell_overhead_press',
        'sets': 4,
        'reps': 8,
        'weight': 95.0,
        'rest_seconds': 150,
        'order': 3,
      },
      {
        'exercise_id': 'dumbbell_lateral_raise',
        'sets': 3,
        'reps': 12,
        'weight': 30.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'cable_tricep_pushdown',
        'sets': 3,
        'reps': 12,
        'weight': 50.0,
        'rest_seconds': 60,
        'order': 5,
      },
    ],
  });

  await pplSessions.doc('pull_day_a').set({
    'session_name': 'Pull Day A',
    'workout_split': 'Pull',
    'day_number': 2,
    'notes': 'Focus on back and biceps',
    'exercises': [
      {
        'exercise_id': 'deadlift',
        'sets': 3,
        'reps': 5,
        'weight': 185.0,
        'rest_seconds': 240,
        'order': 1,
      },
      {
        'exercise_id': 'assisted_pull_up',
        'sets': 4,
        'reps': 8,
        'weight': null,
        'rest_seconds': 120,
        'order': 2,
      },
      {
        'exercise_id': 'barbell_row',
        'sets': 4,
        'reps': 10,
        'weight': 135.0,
        'rest_seconds': 120,
        'order': 3,
      },
      {
        'exercise_id': 'dumbbell_row',
        'sets': 3,
        'reps': 12,
        'weight': 50.0,
        'rest_seconds': 90,
        'order': 4,
      },
      {
        'exercise_id': 'barbell_curl',
        'sets': 3,
        'reps': 12,
        'weight': 50.0,
        'rest_seconds': 60,
        'order': 5,
      },
    ],
  });

  await pplSessions.doc('leg_day_a').set({
    'session_name': 'Leg Day A',
    'workout_split': 'Legs',
    'day_number': 3,
    'notes': 'Focus on quads and glutes',
    'exercises': [
      {
        'exercise_id': 'barbell_squat',
        'sets': 4,
        'reps': 8,
        'weight': 185.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'romanian_deadlift',
        'sets': 3,
        'reps': 10,
        'weight': 135.0,
        'rest_seconds': 120,
        'order': 2,
      },
      {
        'exercise_id': 'leg_press',
        'sets': 3,
        'reps': 12,
        'weight': 185.0,
        'rest_seconds': 90,
        'order': 3,
      },
      {
        'exercise_id': 'leg_extension',
        'sets': 3,
        'reps': 15,
        'weight': 95.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'seated_calf_raise',
        'sets': 4,
        'reps': 20,
        'weight': null,
        'rest_seconds': 45,
        'order': 5,
      },
    ],
  });

  // PPL: Push Day B
  await pplSessions.doc('push_day_b').set({
    'session_name': 'Push Day B',
    'workout_split': 'Push',
    'day_number': 4,
    'notes': 'Chest and triceps volume day',
    'exercises': [
      {
        'exercise_id': 'incline_machine_chest_press',
        'sets': 4,
        'reps': 10,
        'weight': 120.0,
        'rest_seconds': 120,
        'order': 1,
      },
      {
        'exercise_id': 'pec_deck_fly',
        'sets': 3,
        'reps': 12,
        'weight': 80.0,
        'rest_seconds': 90,
        'order': 2,
      },
      {
        'exercise_id': 'dumbbell_shoulder_press',
        'sets': 3,
        'reps': 12,
        'weight': 40.0,
        'rest_seconds': 90,
        'order': 3,
      },
      {
        'exercise_id': 'dumbbell_lateral_raise',
        'sets': 4,
        'reps': 15,
        'weight': 20.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'skull_crusher',
        'sets': 3,
        'reps': 12,
        'weight': 60.0,
        'rest_seconds': 60,
        'order': 5,
      },
    ],
  });

  // PPL: Pull Day B
  await pplSessions.doc('pull_day_b').set({
    'session_name': 'Pull Day B',
    'workout_split': 'Pull',
    'day_number': 5,
    'notes': 'Back and biceps volume day',
    'exercises': [
      {
        'exercise_id': 'lat_pulldown',
        'sets': 4,
        'reps': 10,
        'weight': 100.0,
        'rest_seconds': 120,
        'order': 1,
      },
      {
        'exercise_id': 'seated_cable_row',
        'sets': 4,
        'reps': 10,
        'weight': 110.0,
        'rest_seconds': 120,
        'order': 2,
      },
      {
        'exercise_id': 'machine_row',
        'sets': 3,
        'reps': 12,
        'weight': 90.0,
        'rest_seconds': 90,
        'order': 3,
      },
      {
        'exercise_id': 'dumbbell_curl',
        'sets': 3,
        'reps': 12,
        'weight': 30.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'preacher_curl',
        'sets': 3,
        'reps': 12,
        'weight': 50.0,
        'rest_seconds': 60,
        'order': 5,
      },
    ],
  });

  // PPL: Leg Day B
  await pplSessions.doc('leg_day_b').set({
    'session_name': 'Leg Day B',
    'workout_split': 'Legs',
    'day_number': 6,
    'notes': 'Hamstring and glute focus',
    'exercises': [
      {
        'exercise_id': 'smith_machine_squat',
        'sets': 4,
        'reps': 10,
        'weight': 155.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'lying_leg_curl',
        'sets': 4,
        'reps': 12,
        'weight': 80.0,
        'rest_seconds': 90,
        'order': 2,
      },
      {
        'exercise_id': 'leg_extension',
        'sets': 3,
        'reps': 15,
        'weight': 85.0,
        'rest_seconds': 60,
        'order': 3,
      },
      {
        'exercise_id': 'hip_abduction',
        'sets': 3,
        'reps': 15,
        'weight': 70.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'seated_calf_raise',
        'sets': 4,
        'reps': 20,
        'weight': 90.0,
        'rest_seconds': 45,
        'order': 5,
      },
    ],
  });

  // Program 2: Strength Building
  final sbRef = db.collection('programs').doc('strength_building');
  await sbRef.set({
    'program_name': 'Strength Building Program',
    'goal': 'strength',
    'duration_weeks': 8,
    'days_per_week': 4,
    'difficulty_level': 'advanced',
    'description': 'Low-rep compound-focused strength program',
    'created_at': FieldValue.serverTimestamp(),
  });

  final sbSessions = sbRef.collection('sessions');

  await sbSessions.doc('upper_power').set({
    'session_name': 'Upper Power',
    'workout_split': 'Upper',
    'day_number': 1,
    'notes': 'Heavy compound pressing and rowing',
    'exercises': [
      {
        'exercise_id': 'flat_barbell_bench_press',
        'sets': 4,
        'reps': 5,
        'weight': 205.0,
        'rest_seconds': 240,
        'order': 1,
      },
      {
        'exercise_id': 'barbell_overhead_press',
        'sets': 3,
        'reps': 5,
        'weight': 115.0,
        'rest_seconds': 180,
        'order': 2,
      },
      {
        'exercise_id': 'barbell_row',
        'sets': 4,
        'reps': 5,
        'weight': 155.0,
        'rest_seconds': 180,
        'order': 3,
      },
      {
        'exercise_id': 'assisted_pull_up',
        'sets': 3,
        'reps': 6,
        'weight': null,
        'rest_seconds': 150,
        'order': 4,
      },
    ],
  });

  await sbSessions.doc('lower_power').set({
    'session_name': 'Lower Power',
    'workout_split': 'Lower',
    'day_number': 2,
    'notes': 'Heavy squat and deadlift day',
    'exercises': [
      {
        'exercise_id': 'barbell_squat',
        'sets': 4,
        'reps': 5,
        'weight': 225.0,
        'rest_seconds': 300,
        'order': 1,
      },
      {
        'exercise_id': 'deadlift',
        'sets': 3,
        'reps': 3,
        'weight': 275.0,
        'rest_seconds': 300,
        'order': 2,
      },
      {
        'exercise_id': 'leg_press',
        'sets': 3,
        'reps': 6,
        'weight': 270.0,
        'rest_seconds': 180,
        'order': 3,
      },
    ],
  });

  await sbSessions.doc('upper_hypertrophy').set({
    'session_name': 'Upper Hypertrophy',
    'workout_split': 'Upper',
    'day_number': 4,
    'notes': 'Higher rep upper body accessories',
    'exercises': [
      {
        'exercise_id': 'incline_barbell_bench_press',
        'sets': 4,
        'reps': 10,
        'weight': 155.0,
        'rest_seconds': 120,
        'order': 1,
      },
      {
        'exercise_id': 'dumbbell_shoulder_press',
        'sets': 3,
        'reps': 12,
        'weight': 45.0,
        'rest_seconds': 90,
        'order': 2,
      },
      {
        'exercise_id': 'cable_tricep_pushdown',
        'sets': 3,
        'reps': 12,
        'weight': 55.0,
        'rest_seconds': 60,
        'order': 3,
      },
      {
        'exercise_id': 'barbell_curl',
        'sets': 3,
        'reps': 12,
        'weight': 55.0,
        'rest_seconds': 60,
        'order': 4,
      },
      {
        'exercise_id': 'dumbbell_lateral_raise',
        'sets': 3,
        'reps': 15,
        'weight': 20.0,
        'rest_seconds': 60,
        'order': 5,
      },
    ],
  });

  await sbSessions.doc('lower_hypertrophy').set({
    'session_name': 'Lower Hypertrophy',
    'workout_split': 'Lower',
    'day_number': 5,
    'notes': 'Quad and hamstring isolation work',
    'exercises': [
      {
        'exercise_id': 'leg_press',
        'sets': 4,
        'reps': 12,
        'weight': 230.0,
        'rest_seconds': 120,
        'order': 1,
      },
      {
        'exercise_id': 'leg_extension',
        'sets': 3,
        'reps': 15,
        'weight': 100.0,
        'rest_seconds': 60,
        'order': 2,
      },
      {
        'exercise_id': 'lying_leg_curl',
        'sets': 3,
        'reps': 12,
        'weight': 80.0,
        'rest_seconds': 60,
        'order': 3,
      },
      {
        'exercise_id': 'seated_calf_raise',
        'sets': 4,
        'reps': 20,
        'weight': 90.0,
        'rest_seconds': 45,
        'order': 4,
      },
    ],
  });

  // Program 3: Beginner Full Body
  final bfbRef = db.collection('programs').doc('beginner_full_body');
  await bfbRef.set({
    'program_name': 'Beginner Full Body Template',
    'goal': 'general_fitness',
    'duration_weeks': 4,
    'days_per_week': 3,
    'difficulty_level': 'beginner',
    'description': '3-day full body workout for beginners',
    'created_at': FieldValue.serverTimestamp(),
  });

  final bfbSessions = bfbRef.collection('sessions');

  await bfbSessions.doc('full_body_a').set({
    'session_name': 'Full Body Workout A',
    'workout_split': 'Full Body',
    'day_number': 1,
    'notes': 'Squat, bench, row — add weight each session',
    'exercises': [
      {
        'exercise_id': 'barbell_squat',
        'sets': 3,
        'reps': 5,
        'weight': 95.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'flat_barbell_bench_press',
        'sets': 3,
        'reps': 5,
        'weight': 95.0,
        'rest_seconds': 180,
        'order': 2,
      },
      {
        'exercise_id': 'barbell_row',
        'sets': 3,
        'reps': 5,
        'weight': 95.0,
        'rest_seconds': 180,
        'order': 3,
      },
    ],
  });

  await bfbSessions.doc('full_body_b').set({
    'session_name': 'Full Body Workout B',
    'workout_split': 'Full Body',
    'day_number': 3,
    'notes': 'Squat, overhead press, deadlift',
    'exercises': [
      {
        'exercise_id': 'barbell_squat',
        'sets': 3,
        'reps': 5,
        'weight': 95.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'barbell_overhead_press',
        'sets': 3,
        'reps': 5,
        'weight': 65.0,
        'rest_seconds': 180,
        'order': 2,
      },
      {
        'exercise_id': 'deadlift',
        'sets': 1,
        'reps': 5,
        'weight': 135.0,
        'rest_seconds': 240,
        'order': 3,
      },
    ],
  });

  await bfbSessions.doc('full_body_c').set({
    'session_name': 'Full Body Workout C',
    'workout_split': 'Full Body',
    'day_number': 5,
    'notes': 'Repeat A with heavier weights',
    'exercises': [
      {
        'exercise_id': 'barbell_squat',
        'sets': 3,
        'reps': 5,
        'weight': 100.0,
        'rest_seconds': 180,
        'order': 1,
      },
      {
        'exercise_id': 'flat_barbell_bench_press',
        'sets': 3,
        'reps': 5,
        'weight': 100.0,
        'rest_seconds': 180,
        'order': 2,
      },
      {
        'exercise_id': 'barbell_row',
        'sets': 3,
        'reps': 5,
        'weight': 100.0,
        'rest_seconds': 180,
        'order': 3,
      },
    ],
  });

  debugPrint('Seeded programs (3) with sessions');
}
