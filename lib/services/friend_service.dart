import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';
import '../models/app_user.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Search for a user by exact email. Returns null if not found or is self.
  Future<AppUser?> searchByEmail(String email, String myUid) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    if (doc.id == myUid) return null; // don't return self
    return AppUser.fromMap(doc.id, doc.data());
  }

  /// Stream the current user's friends subcollection.
  Stream<List<Friend>> friendsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Friend.fromMap(d.id, d.data())).toList());
  }

  /// Get the friendship doc for a single friend (to check existing status).
  Future<Friend?> getFriendDoc(String myUid, String targetUid) async {
    final snap = await _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(targetUid)
        .get();
    if (!snap.exists) return null;
    return Friend.fromMap(snap.id, snap.data()!);
  }

  /// Send a friend request from [myUser] to [targetUid].
  /// Writes to: A/friends/B, B/friends/A, B/notifications/new.
  Future<void> sendRequest(AppUser myUser, String targetUid, String targetName) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    // A → B: pending_sent
    final aRef = _db
        .collection('users')
        .doc(myUser.uid)
        .collection('friends')
        .doc(targetUid);
    batch.set(aRef, {
      'status': 'pending_sent',
      'displayName': targetName,
      'email': '', // will be filled from search result in UI
      'addedAt': now,
    });

    // B → A: pending_received
    final bRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('friends')
        .doc(myUser.uid);
    batch.set(bRef, {
      'status': 'pending_received',
      'displayName': myUser.displayName,
      'email': myUser.email,
      'addedAt': now,
    });

    // Notification for B
    final notifRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc();
    batch.set(notifRef, {
      'type': 'friend_request',
      'fromUserId': myUser.uid,
      'fromUserName': myUser.displayName,
      'title': 'Friend Request',
      'message': '${myUser.displayName} wants to be your GymBro! 💪',
      'read': false,
      'actionDone': false,
      'createdAt': now,
    });

    await batch.commit();
  }

  /// Accept a friend request. myUid = the person accepting, fromUid = the sender.
  Future<void> acceptRequest(
      String myUid, String myName, String fromUid, String fromUserName) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    // B: accepted
    final bRef = _db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(fromUid);
    batch.update(bRef, {'status': 'accepted', 'acceptedAt': now});

    // A: accepted
    final aRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(myUid);
    batch.update(aRef, {'status': 'accepted', 'acceptedAt': now});

    // Notification for A (the original sender)
    final notifRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('notifications')
        .doc();
    batch.set(notifRef, {
      'type': 'friend_accepted',
      'fromUserId': myUid,
      'fromUserName': myName,
      'title': 'Friend Request Accepted',
      'message': '$myName accepted your friend request! 🎉',
      'read': false,
      'actionDone': false,
      'createdAt': now,
    });

    await batch.commit();
  }

  /// Decline a friend request — deletes both docs.
  Future<void> declineRequest(String myUid, String fromUid) async {
    final batch = _db.batch();
    batch.delete(_db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(fromUid));
    batch.delete(_db
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(myUid));
    await batch.commit();
  }

  /// Remove an accepted friend — deletes both docs.
  Future<void> removeFriend(String myUid, String friendUid) async {
    final batch = _db.batch();
    batch.delete(_db
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(friendUid));
    batch.delete(_db
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(myUid));
    await batch.commit();
  }

  /// Cancel a sent request (pending_sent) — deletes both docs.
  Future<void> cancelRequest(String myUid, String targetUid) async {
    await declineRequest(myUid, targetUid);
  }
}
