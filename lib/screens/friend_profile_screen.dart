import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';

class FriendProfileScreen extends ConsumerWidget {
  final AppUser friend;
  const FriendProfileScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserDocProvider).value;

    final levelColors = {
      'beginner': const Color(0xFF4CAF50),
      'intermediate': const Color(0xFFFF9800),
      'advanced': const Color(0xFFE53935),
    };
    final levelColor = levelColors[friend.fitnessLevel] ?? const Color(0xFF3F51B5);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF283593),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF283593), Color(0xFF5C6BC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        friend.displayName.isNotEmpty
                            ? friend.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(friend.displayName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(friend.gymName,
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Read-only badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withAlpha(60)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('Read-only profile', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fitness level
                _InfoCard(
                  icon: Icons.fitness_center,
                  iconColor: levelColor,
                  label: 'Fitness Level',
                  value: friend.fitnessLevel[0].toUpperCase() + friend.fitnessLevel.substring(1),
                  valueColor: levelColor,
                ),
                const SizedBox(height: 12),

                // Gym
                _InfoCard(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF3F51B5),
                  label: 'Gym',
                  value: friend.gymName.isEmpty ? 'Not specified' : friend.gymName,
                ),
                const SizedBox(height: 12),

                // Bio
                if (friend.bio.isNotEmpty) ...[
                  _InfoCard(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF00897B),
                    label: 'Bio',
                    value: friend.bio,
                  ),
                  const SizedBox(height: 12),
                ],

                // Email
                _InfoCard(
                  icon: Icons.email_outlined,
                  iconColor: Colors.grey,
                  label: 'Email',
                  value: friend.email,
                ),

                if (me != null && me.uid == friend.uid)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text("This is your own profile", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? const Color(0xFF1A1A2E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
