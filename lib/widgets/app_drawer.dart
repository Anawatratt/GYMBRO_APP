import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width * 0.78;

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
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DrawerHeader(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
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
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Logout footer
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref
                                .read(authNotifierProvider.notifier)
                                .logout();
                          },
                          icon: const Icon(Icons.logout, color: Colors.black54),
                          label: const Text('Logout',
                              style: TextStyle(color: Colors.black87)),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                          ),
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

class _DrawerHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final name = profile?.name ?? 'User';
        final initials = profile?.initials ?? '?';
        const avatarColor = Color(0xFFE53935);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              profile?.imageUrl != null
                  ? CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(profile!.imageUrl!),
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: avatarColor,
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('@${profile?.username ?? ''}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(height: 56),
      ),
      error: (_, __) => const SizedBox(height: 72),
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
      leading: Icon(icon, color: Colors.black87),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      horizontalTitleGap: 4,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
      visualDensity: VisualDensity.compact,
      tileColor: Colors.transparent,
      hoverColor: Colors.grey[100],
      splashColor: Colors.grey.withAlpha(40),
    );
  }
}
