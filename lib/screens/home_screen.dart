import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/program_provider.dart';
import '../widgets/app_drawer.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF111111),
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(scaffoldKey: scaffoldKey),
              const SizedBox(height: 20),
              const _HomeContent(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Navigation Bar ────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _TopBar({required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.menu_rounded,
            onTap: () => scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Center(
              child: CachedNetworkImage(
                imageUrl:
                    'https://firebasestorage.googleapis.com/v0/b/gymbro-f4ff7.firebasestorage.app/o/Screenshot%202026-03-11%20134028.png?alt=media&token=57485e66-36dc-4bca-9ea1-bb5aad4265fa',
                height: 36,
                placeholder: (_, __) => const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.fitness_center,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
            ),
          ),
          Stack(
            children: [
              _NavBtn(
                icon: Icons.notifications_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
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
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Home Content ─────────────────────────────────────────

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _uploadingPhoto = false;

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    final appUser = ref.read(currentUserDocProvider).value;
    if (appUser == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final svc = ref.read(userServiceProvider);
      final url = await svc.uploadProfileImage(appUser.uid, File(picked.path));
      await svc.updateProfileImageUrl(appUser.uid, url);
      await CachedNetworkImage.evictFromCache('profile_${appUser.uid}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayCount =
        ref.watch(todayWorkoutProvider).value?.exercises.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(
          onChangePhoto: _changePhoto,
          uploading: _uploadingPhoto,
          todayCount: todayCount,
        ),
        const SizedBox(height: 24),
        const Text(
          "Today's Workout",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const _TodaysWorkoutCard(),
      ],
    );
  }
}

// ── Profile Card ─────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  final VoidCallback? onChangePhoto;
  final bool uploading;
  final int todayCount;
  const _ProfileCard(
      {this.onChangePhoto, this.uploading = false, this.todayCount = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentUserDocProvider).value;
    final streak = appUser?.dayStreak ?? 0;
    final name = (appUser?.displayName.isNotEmpty == true)
        ? appUser!.displayName
        : 'User';
    final initials = name != 'User' ? name[0].toUpperCase() : '?';
    final photoUrl =
        (appUser?.photoUrl.isNotEmpty == true) ? appUser!.photoUrl : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1C1C1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: avatar / image with edit button
              SizedBox(
                width: 130,
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
                    if (photoUrl != null)
                      CachedNetworkImage(
                        imageUrl: photoUrl,
                        cacheKey: 'profile_${appUser!.uid}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800)),
                        ),
                      )
                    else
                      Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800)),
                      ),
                    if (uploading)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onChangePhoto,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withAlpha(180),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right: name + stats
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          _StatRaw(
                            icon: Icons.local_fire_department_rounded,
                            value: '$streak',
                            label: 'Streak',
                            iconColor: const Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 20),
                          _StatRaw(
                            icon: Icons.fitness_center_rounded,
                            value: '$todayCount',
                            label: 'Today',
                            iconColor: Colors.white,
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
      ),
    );
  }
}

class _StatRaw extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatRaw({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(width: 5),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
      ],
    );
  }
}

// ── Today's Workout Card ──────────────────────────────────

class _TodaysWorkoutCard extends ConsumerWidget {
  const _TodaysWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final programName = todayAsync.value?.programName ?? '';
    final sessionName = todayAsync.value?.sessionName ?? '';
    final programId = todayAsync.value?.programId ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1C1C1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todayAsync.isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6B6B6B)),
                )
              else if (programName.isEmpty)
                const Text(
                  'No active program',
                  style: TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                )
              else
                Text(
                  programName,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              if (sessionName.isNotEmpty)
                Text(
                  'Goal: $sessionName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => programId.isNotEmpty
                      ? Navigator.pushNamed(context, '/planDetail',
                          arguments: {
                            'programId': programId,
                            'programName': programName,
                          })
                      : Navigator.pushNamed(context, '/plans'),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withAlpha(100),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 80),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Start Workout',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
