import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref
          .watch(notificationServiceProvider)
          .notificationsStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Derived count of unread notifications.
final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider);
  return notifications.when(
    data: (list) => list.where((n) => !n.read).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final notificationWatcherProvider = Provider<void>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  
  // keep track of notifications we've already "seen" in this session
  // so we don't spam multiple banners.
  final seenNotificationIds = ref.watch(_seenIdsProvider);

  notificationsAsync.whenData((list) {
    for (final notify in list) {
      if (!notify.read && !seenNotificationIds.contains(notify.id)) {
        seenNotificationIds.add(notify.id);
        
        // Show local banner
        LocalNotificationService.instance.show(notify);
      }
    }
  });
});

final _seenIdsProvider = Provider<Set<String>>((ref) => {});
