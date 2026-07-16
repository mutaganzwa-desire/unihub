import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM + local-notification fallback. Foreground pushes are re-shown through
/// flutter_local_notifications because FCM does not display them itself.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'unihub_default',
    'UniHub notifications',
    description: 'Applications, messages and internship updates',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  Future<String?> getToken() => _fcm.getToken();

  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Data-only messages could be handled here (e.g. badge sync).
}
