import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String friendUid;
  final String status; // pending_sent | pending_received | accepted
  final String displayName;
  final String email;
  final DateTime addedAt;
  final DateTime? acceptedAt;

  const Friend({
    required this.friendUid,
    required this.status,
    required this.displayName,
    required this.email,
    required this.addedAt,
    this.acceptedAt,
  });

  factory Friend.fromMap(String friendUid, Map<String, dynamic> map) {
    return Friend(
      friendUid: friendUid,
      status: map['status'] as String? ?? 'pending_received',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'displayName': displayName,
      'email': email,
      'addedAt': Timestamp.fromDate(addedAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    };
  }

  Friend copyWith({
    String? status,
    DateTime? acceptedAt,
  }) {
    return Friend(
      friendUid: friendUid,
      status: status ?? this.status,
      displayName: displayName,
      email: email,
      addedAt: addedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
