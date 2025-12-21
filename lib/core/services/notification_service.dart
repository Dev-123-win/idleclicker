import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    // TODO: Senior Dev Pro-Tip: On Android 8.0+, once a notification channel is created,
    // you cannot change its sound or vibration programmatically without deleting
    // and recreating the channel. If you change the sound file later, remember
    // to change the 'custom_notification_channel' id or reinstall the app.

    // Create the high importance channel for Android 8.0+
    // This is required for custom sound and vibration to work on newer Android versions
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'custom_notification_channel', // id
      'App Notifications', // title
      description: 'Notifications with custom sound and vibration',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sfx'),
      enableVibration: true,
      vibrationPattern:
          vibrationPattern, // 0ms delay, 1s vibrate, 0.5s pause, 1s vibrate
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Trigger a notification with custom sound and vibration
  Future<void> triggerNotification({
    int id = 0,
    String title = 'Notification',
    String body = 'This is a custom notification!',
  }) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'custom_notification_channel',
          'App Notifications',
          channelDescription: 'Notifications with custom sound and vibration',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification_sfx'),
          enableVibration: true,
          vibrationPattern: vibrationPattern,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }
}
