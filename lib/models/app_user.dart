import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final String fitnessLevel; // beginner | intermediate | advanced
  final String gymName;
  final bool profileComplete;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int dayStreak;
  final DateTime? lastWorkoutDate;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.bio = '',
    this.fitnessLevel = 'beginner',
    this.gymName = 'CMU Gym',
    this.profileComplete = false,
    required this.createdAt,
    required this.lastLoginAt,
    this.dayStreak = 0,
    this.lastWorkoutDate,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      fitnessLevel: map['fitnessLevel'] as String? ?? 'beginner',
      gymName: map['gymName'] as String? ?? 'CMU Gym',
      profileComplete: map['profileComplete'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dayStreak: map['dayStreak'] as int? ?? 0,
      lastWorkoutDate: (map['lastWorkoutDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'fitnessLevel': fitnessLevel,
      'gymName': gymName,
      'profileComplete': profileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    String? fitnessLevel,
    String? gymName,
    bool? profileComplete,
    DateTime? lastLoginAt,
    int? dayStreak,
    DateTime? lastWorkoutDate,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      gymName: gymName ?? this.gymName,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      dayStreak: dayStreak ?? this.dayStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }
}
