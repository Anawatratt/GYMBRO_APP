import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // friend_request | friend_accepted | workout_complete
  final String fromUserId;
  final String fromUserName;
  final String title;
  final String message;
  final bool read;
  final bool actionDone;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUserName,
    required this.title,
    required this.message,
    this.read = false,
    this.actionDone = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: map['type'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      fromUserName: map['fromUserName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      actionDone: map['actionDone'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'title': title,
      'message': message,
      'read': read,
      'actionDone': actionDone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({bool? read, bool? actionDone}) {
    return AppNotification(
      id: id,
      type: type,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      title: title,
      message: message,
      read: read ?? this.read,
      actionDone: actionDone ?? this.actionDone,
      createdAt: createdAt,
    );
  }
}
