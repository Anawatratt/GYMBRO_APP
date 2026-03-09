import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_state.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(scaffoldKey: _scaffoldKey),
              const SizedBox(height: 20),
              profileAsync.when(
                data: (profile) => _HomeContent(profile: profile),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const _HomeContent(profile: null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Navigation Bar ────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _TopBar({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.menu_rounded,
            onTap: () => scaffoldKey.currentState?.openDrawer(),
          ),
          const Expanded(
            child: Text(
              'Home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          _NavBtn(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: const Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}

// ── Home Content ─────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final UserProfile? profile;
  const _HomeContent({this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(profile: profile),
        const SizedBox(height: 24),
        const Text(
          "Today's Workout",
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        const _TodaysWorkoutCard(),
        const SizedBox(height: 24),
        const Text(
          'Quick Actions',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        const _QuickActions(),
      ],
    );
  }
}

// ── Profile Card ─────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  const _ProfileCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'User';
    final initials = profile?.initials ?? '?';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top: image + user info
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: athlete image / avatar
                  SizedBox(
                    width: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        if (profile?.imageUrl != null)
                          Image.network(
                            profile!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800)),
                            ),
                          )
                        else
                          Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800)),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(60),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: name + stats
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Stat row
                          Row(
                            children: [
                              _StatChip(
                                icon: Icons.local_fire_department_rounded,
                                color: const Color(0xFFE53935),
                                value: '0',
                                label: 'Streak',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                icon: Icons.fitness_center_rounded,
                                color: const Color(0xFF1A1A2E),
                                value: '0',
                                label: 'Today',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style:
                      TextStyle(fontSize: 9, color: color.withAlpha(160))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Today's Workout Card ──────────────────────────────────

class _TodaysWorkoutCard extends StatelessWidget {
  const _TodaysWorkoutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beginner Fundamentals 4-Week',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Leg Day A',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Tag(label: 'Strength', color: const Color(0xFFE53935)),
                      const SizedBox(width: 8),
                      _Tag(
                          label: '6 Exercises',
                          color: const Color(0xFF1A1A2E)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Full-width start button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/plans'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text(
                        'Start Workout',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.search_rounded,
        label: 'Search',
        color: const Color(0xFFE53935),
        route: '/search',
      ),
      _ActionItem(
        icon: Icons.calendar_month_rounded,
        label: 'Plans',
        color: const Color(0xFF1A1A2E),
        route: '/plans',
      ),
      _ActionItem(
        icon: Icons.bar_chart_rounded,
        label: 'Progress',
        color: const Color(0xFFE53935),
        route: '/progressAnalytics',
      ),
      _ActionItem(
        icon: Icons.sticky_note_2_rounded,
        label: 'Notes',
        color: const Color(0xFF1A1A2E),
        route: '/notes',
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: actions
          .map((a) => _ActionTile(item: a))
          .toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.route});
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: item.color.withAlpha(80),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }
}
