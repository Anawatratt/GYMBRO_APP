import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/friend_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsStreamProvider).value ?? [];
    final me = ref.watch(currentUserDocProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => n.read))
            TextButton(
              onPressed: () async {
                if (me == null) return;
                final svc = ref.read(notificationServiceProvider);
                for (final n in notifications.where((n) => !n.read)) {
                  await svc.markRead(me.uid, n.id);
                }
              },
              child: const Text('Mark all read', style: TextStyle(color: Color(0xFF3F51B5))),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    if (me == null) return;
                    if (!n.read) {
                      await ref.read(notificationServiceProvider).markRead(me.uid, n.id);
                    }
                  },
                  onAccept: n.type == 'friend_request' && !n.actionDone && me != null
                      ? () async {
                          await ref.read(notificationServiceProvider).markActionDone(me.uid, n.id);
                          await ref.read(friendServiceProvider).acceptRequest(
                                me.uid, me.displayName, n.fromUserId, n.fromUserName);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('You and ${n.fromUserName} are now GymBros! 💪'), backgroundColor: const Color(0xFF3F51B5)),
                            );
                          }
                        }
                      : null,
                  onDecline: n.type == 'friend_request' && !n.actionDone && me != null
                      ? () async {
                          await ref.read(notificationServiceProvider).markActionDone(me.uid, n.id);
                          await ref.read(friendServiceProvider).declineRequest(me.uid, n.fromUserId);
                        }
                      : null,
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'friend_accepted':
        return Icons.people_rounded;
      case 'workout_complete':
        return Icons.fitness_center_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notification.type) {
      case 'friend_request':
        return const Color(0xFF3F51B5);
      case 'friend_accepted':
        return const Color(0xFF00897B);
      case 'workout_complete':
        return const Color(0xFFFF7043);
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? _color.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: unread ? Border.all(color: _color.withAlpha(40), width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(notification.title,
                                style: TextStyle(
                                    fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 14,
                                    color: const Color(0xFF1A1A2E))),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(notification.message,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_timeAgo(notification.createdAt),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            // Action buttons for unhandled friend requests
            if (onAccept != null && onDecline != null && !notification.actionDone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onDecline,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (notification.actionDone && notification.type == 'friend_request') ...[
              const SizedBox(height: 8),
              Text('Already responded', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
