import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_notification.dart';

/// Wrapper around FlutterLocalNotificationsPlugin.
/// Call [initialize] once at app startup, then [show] whenever you want a
/// phone-level banner.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// High-importance Android channel for all GymBro alerts.
  static const _channel = AndroidNotificationChannel(
    'gymbro_alerts',
    'GymBro Alerts',
    description: 'Friend requests, workout nudges and other GymBro alerts.',
    importance: Importance.high,
    playSound: true,
  );

  /// Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Create the channel on Android
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: initSettings);

    // Ask the user for the POST_NOTIFICATIONS permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Show a local notification for an [AppNotification].
  Future<void> show(AppNotification n) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: _iconFor(n.type),
      ),
    );

    await _plugin.show(
      id: n.id.hashCode,
      title: n.title,
      body: n.message,
      notificationDetails: details,
    );
  }

  String _iconFor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return '@mipmap/ic_launcher';
      default:
        return '@mipmap/ic_launcher';
    }
  }
}
