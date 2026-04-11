import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Check for custom alarm path
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('custom_alarm_path');
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'security_alerts_v2',
      'Security Alerts',
      description: 'Critical motion and security alarms',
      importance: Importance.max,
      playSound: true,
      sound: customPath != null
          ? UriAndroidNotificationSound(customPath)
          : const RawResourceAndroidNotificationSound('siren'),
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? "Security Alert",
          body: message.notification!.body ?? "Motion Detected",
        );
      }
    });

    // Handle background notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigation is usually handled via a global navigator key or a specific protocol
      // For this app, we'll assume the main entry point handles deep links or we provide a static method
    });
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('custom_alarm_path');

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'security_alerts_v2',
          'Security Alerts',
          channelDescription: 'Critical motion and security alarms',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          sound: customPath != null
              ? UriAndroidNotificationSound(customPath)
              : const RawResourceAndroidNotificationSound('siren'),
          playSound: true,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'stop_buzzer',
              'STOP BUZZER',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(id, title, body, platformChannelSpecifics);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_buzzer') {
      _handleStopBuzzer();
    }
  }

  static Future<void> _handleStopBuzzer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId =
          prefs.getString('flutter.esp32_device_id')?.replaceAll('"', '') ??
          AppConstants.defaultDeviceId;
      final db = FirebaseDatabase.instance.ref();

      // 1. Send silent command to ESP32
      await db.child('devices/$deviceId/commands/alarm_disable').set(true);

      // 2. Clear visual alarm state in Firebase
      await db.child('devices/$deviceId/security/alarmActive').set(false);

      debugPrint("Hardware buzzer stopped from Dart Notification Action");
    } catch (e) {
      debugPrint("Error stopping buzzer from Dart: $e");
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == 'stop_buzzer') {
    NotificationService._handleStopBuzzer();
  }
}
