import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? taggedFriendUid;
  final String? taggedFriendName;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.taggedFriendUid,
    this.taggedFriendName,
  });

  bool get hasTag => taggedFriendUid != null && taggedFriendName != null;

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taggedFriendUid: map['taggedFriendUid'] as String?,
      taggedFriendName: map['taggedFriendName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (taggedFriendUid != null) 'taggedFriendUid': taggedFriendUid,
      if (taggedFriendName != null) 'taggedFriendName': taggedFriendName,
    };
  }

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    Object? taggedFriendUid = _sentinel,
    Object? taggedFriendName = _sentinel,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taggedFriendUid: taggedFriendUid == _sentinel
          ? this.taggedFriendUid
          : taggedFriendUid as String?,
      taggedFriendName: taggedFriendName == _sentinel
          ? this.taggedFriendName
          : taggedFriendName as String?,
    );
  }
}

const _sentinel = Object();
