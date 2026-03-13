import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/friends_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../providers/friend_provider.dart';
import '../screens/progress_analytics_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width * 0.78;
    final user = ref.watch(currentUserDocProvider).value;
    final unread = ref.watch(unreadCountProvider);
    final acceptedFriends = (ref.watch(friendsStreamProvider).value ?? [])
        .where((f) => f.status == 'accepted')
        .toList()
      ..sort((a, b) => (a.acceptedAt ?? a.addedAt)
          .compareTo(b.acceptedAt ?? b.addedAt));

    return Drawer(
      width: width,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        child: Material(
          color: const Color(0xFF161618),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE53935),
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Loading...',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.fitnessLevel ?? '',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // ── Menu ─────────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _MenuItemTile(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (r) => false);
                          },
                        ),
                        _MenuItemTile(
                          icon: Icons.search_rounded,
                          title: 'Search',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/search');
                          },
                        ),
                        _MenuItemTile(
                          icon: Icons.calendar_month_rounded,
                          title: 'Workout Plan',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/plans');
                          },
                        ),
                        _ProgressExpansionTile(
                          user: user,
                          friends: acceptedFriends,
                          onNavigate: () => Navigator.pop(context),
                        ),
                        _MenuItemTile(
                          icon: Icons.sticky_note_2_rounded,
                          title: 'Notes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/notes');
                          },
                        ),
                        const Divider(height: 24),
                        _MenuItemTile(
                          icon: Icons.people_rounded,
                          title: 'Friends',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FriendsScreen()));
                          },
                        ),
                        _MenuItemTileWithBadge(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          badge: unread,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen()));
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Footer ───────────────────────────────
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Clear image cache so the next account's images
                              // are always loaded fresh (never shows the wrong user's photo).
                              PaintingBinding.instance.imageCache.clear();
                              PaintingBinding.instance.imageCache.clearLiveImages();
                              await CachedNetworkImage.evictFromCache('');
                              await ref.read(authServiceProvider).signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout,
                                color: Color(0xFF9E9E9E)),
                            label: const Text('Logout',
                                style: TextStyle(color: Colors.white)),
                            style: TextButton.styleFrom(
                                alignment: Alignment.centerLeft),
                          ),
                        ),
                        Text('v1.0.0',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuItemTile(
      {required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      horizontalTitleGap: 4,
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MenuItemTileWithBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final int badge;
  final VoidCallback? onTap;

  const _MenuItemTileWithBadge(
      {required this.icon,
      required this.title,
      required this.badge,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      title: Text(title,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      horizontalTitleGap: 4,
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Progress expansion tile ───────────────────────────────

class _ProgressExpansionTile extends StatelessWidget {
  final dynamic user;
  final List<dynamic> friends;
  final VoidCallback onNavigate;

  const _ProgressExpansionTile({
    required this.user,
    required this.friends,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.bar_chart_rounded, color: Colors.white),
        title: const Text(
          'Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
        iconColor: const Color(0xFF9E9E9E),
        collapsedIconColor: const Color(0xFF6B6B6B),
        children: [
          _SubTile(
            initial: (user?.displayName as String?)?.isNotEmpty == true
                ? (user.displayName as String)[0].toUpperCase()
                : '?',
            name: (user?.displayName as String?) ?? 'Me',
            label: 'Me',
            onTap: () {
              onNavigate();
              Navigator.pushNamed(context, '/progressAnalytics');
            },
          ),
          ...friends.map((f) {
            final name = (f.displayName as String?) ?? '';
            return _SubTile(
              initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
              name: name,
              onTap: () {
                onNavigate();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressAnalyticsScreen(
                        viewUid: f.friendUid as String),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  final String initial;
  final String name;
  final String? label;
  final VoidCallback onTap;

  const _SubTile({
    required this.initial,
    required this.name,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE53935).withAlpha(20),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (label != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
