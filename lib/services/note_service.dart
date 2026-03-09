import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Note>> notesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromMap(d.id, d.data())).toList());
  }

  Future<void> addNote(String uid, String title, String content) async {
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).collection('notes').add({
      'title': title,
      'content': content,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateNote(
      String uid, String noteId, String title, String content) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
