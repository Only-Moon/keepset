import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      const InitializationSettings(android: android),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> sendTestNotification() async {
    await _plugin.show(
      0,
      'Keepset',
      'Notifications are enabled',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'keepset_main',
          'Keepset',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }
}
