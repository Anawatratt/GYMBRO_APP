import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  AppUser? _searchResult;
  String? _searchError;
  bool _searching = false;
  String? _actionLoading; // uid being acted upon

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _searchCtrl.text.trim();
    if (email.isEmpty) return;
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;

    setState(() {
      _searching = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final result = await ref.read(friendServiceProvider).searchByEmail(email, me.uid);
      setState(() {
        _searchResult = result;
        _searchError = result == null ? 'No user found with that email.' : null;
      });
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(AppUser target) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    setState(() => _actionLoading = target.uid);
    try {
      await ref.read(friendServiceProvider).sendRequest(me, target.uid, target.displayName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${target.displayName}! 🎉'), backgroundColor: const Color(0xFF3F51B5)),
        );
        setState(() => _searchResult = null);
        _searchCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  Future<void> _accept(Friend friend) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    setState(() => _actionLoading = friend.friendUid);
    try {
      await ref.read(friendServiceProvider).acceptRequest(me.uid, me.displayName, friend.friendUid, friend.displayName);
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  Future<void> _decline(Friend friend) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    setState(() => _actionLoading = friend.friendUid);
    try {
      await ref.read(friendServiceProvider).declineRequest(me.uid, friend.friendUid);
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  Future<void> _remove(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove ${friend.displayName} from your friends?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    await ref.read(friendServiceProvider).removeFriend(me.uid, friend.friendUid);
  }

  Future<void> _viewProfile(Friend friend) async {
    final user = await ref.read(userServiceProvider).getUserOnce(friend.friendUid);
    if (user != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: user)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsStreamProvider).value ?? [];
    final pending = friends.where((f) => f.status == 'pending_received').toList();
    final sent = friends.where((f) => f.status == 'pending_sent').toList();
    final accepted = friends.where((f) => f.status == 'accepted').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search section
          _SectionHeader(icon: Icons.search_rounded, title: 'Find Friends', color: const Color(0xFF3F51B5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search by email...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _searching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Search'),
                ),
              ),
            ],
          ),

          // Search result
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            Center(child: Text(_searchError!, style: TextStyle(color: Colors.grey[500]))),
          ],
          if (_searchResult != null) ...[
            const SizedBox(height: 12),
            _SearchResultCard(
              user: _searchResult!,
              loading: _actionLoading == _searchResult!.uid,
              onAdd: () => _sendRequest(_searchResult!),
            ),
          ],

          const SizedBox(height: 24),

          // Friend requests
          if (pending.isNotEmpty) ...[
            _SectionHeader(icon: Icons.person_add_rounded, title: 'Friend Requests (${pending.length})', color: const Color(0xFFE53935)),
            const SizedBox(height: 10),
            ...pending.map((f) => _FriendTile(
              friend: f,
              loading: _actionLoading == f.friendUid,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(label: 'Accept', color: const Color(0xFF3F51B5), onTap: () => _accept(f)),
                  const SizedBox(width: 8),
                  _ActionBtn(label: 'Decline', color: Colors.red, outline: true, onTap: () => _decline(f)),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],

          // Sent requests
          if (sent.isNotEmpty) ...[
            _SectionHeader(icon: Icons.send_rounded, title: 'Sent Requests', color: const Color(0xFFFF9800)),
            const SizedBox(height: 10),
            ...sent.map((f) => _FriendTile(
              friend: f,
              loading: _actionLoading == f.friendUid,
              trailing: _ActionBtn(label: 'Cancel', color: Colors.grey, outline: true, onTap: () async {
                final me = ref.read(currentUserDocProvider).value;
                if (me == null) return;
                await ref.read(friendServiceProvider).cancelRequest(me.uid, f.friendUid);
              }),
            )),
            const SizedBox(height: 20),
          ],

          // Friends
          _SectionHeader(icon: Icons.people_rounded, title: 'My Friends (${accepted.length})', color: const Color(0xFF00897B)),
          const SizedBox(height: 10),
          if (accepted.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No friends yet. Search by email to add!', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ),
            )
          else
            ...accepted.map((f) => _FriendTile(
              friend: f,
              loading: _actionLoading == f.friendUid,
              onTap: () => _viewProfile(f),
              trailing: IconButton(
                icon: Icon(Icons.person_remove_outlined, color: Colors.grey[400]),
                onPressed: () => _remove(f),
              ),
            )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final AppUser user;
  final bool loading;
  final VoidCallback onAdd;
  const _SearchResultCard({required this.user, required this.loading, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3F51B5).withAlpha(60)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3F51B5),
            child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: loading ? null : onAdd,
            icon: loading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.person_add, size: 18),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final bool loading;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _FriendTile({required this.friend, this.loading = false, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3F51B5).withAlpha(40),
          child: Text(
            friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: loading
            ? const LinearProgressIndicator()
            : Text(friend.email, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        onTap: onTap,
        trailing: trailing,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outline;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, this.outline = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: outline ? Border.all(color: color) : null,
        ),
        child: Text(label,
            style: TextStyle(color: outline ? color : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
