import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';
import '../models/app_user.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Suggest users whose username starts with [prefix] (up to 5 results).
  Future<List<AppUser>> suggestByPrefix(String prefix, String myUid) async {
    if (prefix.isEmpty) return [];
    // strip leading @ if user typed @username
    final lower = prefix.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
    final query = await _db
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: lower)
        .where('email', isLessThan: '$lower\uf8ff')
        .limit(6)
        .get();
    return query.docs
        .where((d) => d.id != myUid)
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .take(5)
        .toList();
  }

  /// Search for a user by username. Returns null if not found or is self.
  Future<AppUser?> searchByUsername(String username, String myUid) async {
    final email = '${username.trim().toLowerCase()}@gymbro.app';
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    if (doc.id == myUid) return null;
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
  String _nameOf(AppUser u) {
    if (u.displayName.isNotEmpty) return u.displayName;
    final idx = u.email.indexOf('@');
    if (idx > 0) return u.email.substring(0, idx);
    return u.uid.substring(0, 8);
  }

  Future<void> sendRequest(AppUser myUser, AppUser target) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    // A → B: pending_sent
    final aRef = _db
        .collection('users')
        .doc(myUser.uid)
        .collection('friends')
        .doc(target.uid);
    batch.set(aRef, {
      'status': 'pending_sent',
      'displayName': _nameOf(target),
      'email': target.email,
      'addedAt': now,
    });

    // B → A: pending_received
    final bRef = _db
        .collection('users')
        .doc(target.uid)
        .collection('friends')
        .doc(myUser.uid);
    batch.set(bRef, {
      'status': 'pending_received',
      'displayName': _nameOf(myUser),
      'email': myUser.email,
      'addedAt': now,
    });

    // Notification for B
    final notifRef = _db
        .collection('users')
        .doc(target.uid)
        .collection('notifications')
        .doc();
    batch.set(notifRef, {
      'type': 'friend_request',
      'fromUserId': myUser.uid,
      'fromUserName': _nameOf(myUser),
      'title': 'Friend Request',
      'message': '${_nameOf(myUser)} wants to be your GymBro! 💪',
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
