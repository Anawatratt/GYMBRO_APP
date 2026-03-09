import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/friends_screen.dart';
import '../screens/notifications_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width * 0.78;
    final user = ref.watch(currentUserDocProvider).value;
    final unread = ref.watch(unreadCountProvider);

    return Drawer(
      width: width,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        child: Material(
          color: Colors.white,
          child: SafeArea(
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
                        backgroundColor: const Color(0xFF3F51B5),
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
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.fitnessLevel ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                          Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
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
                      _MenuItemTile(
                        icon: Icons.search_rounded,
                        title: 'Search',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/search');
                        },
                      ),
                      _MenuItemTile(
                        icon: Icons.bar_chart_rounded,
                        title: 'Progress',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/progressAnalytics');
                        },
                      ),
                      _MenuItemTile(
                        icon: Icons.sticky_note_2_rounded,
                        title: 'Notes',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/notes');
                        },
                      ),
                      _MenuItemTile(
                        icon: Icons.history_rounded,
                        title: 'Workout History',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/workoutHistory');
                        },
                      ),
                      const Divider(height: 24),
                      _MenuItemTile(
                        icon: Icons.people_rounded,
                        title: 'Friends',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                        },
                      ),
                      _MenuItemTileWithBadge(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        badge: unread,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                // ── Footer ───────────────────────────────
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(authServiceProvider).signOut();
                          },
                          icon: const Icon(Icons.logout, color: Colors.black54),
                          label: const Text('Logout', style: TextStyle(color: Colors.black87)),
                          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                        ),
                      ),
                      Text('v1.0.0', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
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

  const _MenuItemTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      horizontalTitleGap: 4,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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

  const _MenuItemTileWithBadge({required this.icon, required this.title, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.black87),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      horizontalTitleGap: 4,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
