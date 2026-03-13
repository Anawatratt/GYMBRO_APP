import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import 'friend_profile_screen.dart';
import 'qr_screen.dart';

String _usernameTag(String email) {
  final idx = email.indexOf('@');
  if (idx <= 0) return email;
  return '@${email.substring(0, idx)}';
}

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  String? _actionLoading;
  List<AppUser> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    final results = await ref.read(friendServiceProvider).suggestByPrefix(text, me.uid);
    if (mounted) setState(() => _suggestions = results);
  }

  Future<void> _sendRequest(AppUser target) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    setState(() => _actionLoading = target.uid);
    try {
      await ref.read(friendServiceProvider).sendRequest(me, target);
      if (mounted) {
        _searchCtrl.clear();
        setState(() => _suggestions = []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Friend request sent to ${target.displayName.isNotEmpty ? target.displayName : _usernameTag(target.email)}! 🎉',
            ),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  Future<void> _accept(Friend friend) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    setState(() => _actionLoading = friend.friendUid);
    try {
      final myName = me.displayName.isNotEmpty ? me.displayName : me.email.split('@').first;
      await ref.read(friendServiceProvider).acceptRequest(me.uid, myName, friend.friendUid, friend.displayName);
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
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(arguments: {'uid': user.uid, 'name': user.displayName}),
          builder: (_) => const FriendProfileScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsStreamProvider).value ?? [];
    final pending = friends.where((f) => f.status == 'pending_received').toList();
    final sent = friends.where((f) => f.status == 'pending_sent').toList();
    final accepted = friends.where((f) => f.status == 'accepted').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'QR Code',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QRScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search section
          _SectionHeader(icon: Icons.search_rounded, title: 'Find Friends', color: const Color(0xFF3F51B5)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8)],
            ),
            child: TextField(
              controller: _searchCtrl,
              keyboardType: TextInputType.text,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.alternate_email, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Suggestions with Add button
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C2C2E)),
              ),
              child: Column(
                children: _suggestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final user = entry.value;
                  final username = user.email.split('@').first;
                  final name = user.displayName.isNotEmpty ? user.displayName : username;
                  final isLoading = _actionLoading == user.uid;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF3F51B5).withAlpha(40),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF3F51B5), fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('@$username', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : () => _sendRequest(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F51B5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: isLoading
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.person_add, size: 15),
                                label: const Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _suggestions.length - 1)
                        Divider(height: 1, color: const Color(0xFF2C2C2E), indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
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
                child: Text('No friends yet. Search by username to add!',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
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
    final subtitle = friend.email.isNotEmpty ? _usernameTag(friend.email) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
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
            : (subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)) : null),
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
