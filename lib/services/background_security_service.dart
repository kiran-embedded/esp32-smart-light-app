import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class BackgroundSecurityService {
  static const String notificationChannelId = 'nebula_alarm_channel_v3';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'NEBULA CRITICAL ALARM',
      description: 'High priority breakthrough security alarms',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'NEBULA SECURITY ACTIVE',
        initialNotificationContent: 'Grid Secure • Quantum Ready',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    await Firebase.initializeApp();
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(false);
    } catch (_) {}

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final prefs = await SharedPreferences.getInstance();
    final deviceId =
        prefs.getString('esp32_device_id') ?? AppConstants.defaultDeviceId;

    final database = FirebaseDatabase.instance.ref();
    bool isArmed = true;
    bool autoLightOnMotion = false;
    Timer? _autoOffTimer;

    // PATHS
    final String cmdPath = 'devices/$deviceId/commands';
    final String telemetryPath = 'devices/$deviceId/telemetry';
    final String sensorPath = 'devices/$deviceId/security/sensors';

    // State Listeners
    database
        .child('devices/$deviceId/security/autoLightOnMotion')
        .onValue
        .listen((event) {
          autoLightOnMotion = (event.snapshot.value as bool?) ?? false;
          print("NEBULA_BG: AUTO_LIGHT_FLAG = $autoLightOnMotion");
        });

    database.child('devices/$deviceId/security/isArmed').onValue.listen((
      event,
    ) {
      isArmed = (event.snapshot.value as bool?) ?? true;
      print("NEBULA_BG: ARMED_FLAG = $isArmed");
    });

    // Sensor Listener
    database.child(sensorPath).onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        bool anyMotion = false;
        String zone = "Unknown";

        data.forEach((k, v) {
          if (v is Map && v['status'] == true) {
            anyMotion = true;
            zone = k
                .toString()
                .replaceAll('PIR', '')
                .replaceAll('_', ' ')
                .trim();
          }
        });

        if (anyMotion) {
          print(
            "NEBULA_BG: MOTION IN $zone [Armed: $isArmed, Auto: $autoLightOnMotion]",
          );

          if (autoLightOnMotion) {
            print("NEBULA_BG: EXEC_NEURAL_BURST");

            final burstCmds = {
              'relay1': 1,
              'relay2': 1,
              'relay3': 1,
              'relay4': 1,
              'relay5': 1,
              'relay6': 1,
            };

            // DOUBLE-PATH HARDENING: Write to commands AND telemetry
            // This ensures the hardware gets it (commands) AND the UI reflects it (telemetry)
            database.child(cmdPath).update(burstCmds);
            database.child(telemetryPath).update({
              'relay1': true,
              'relay2': true,
              'relay3': true,
              'relay4': true,
              'relay5': true,
              'relay6': true,
            });

            _autoOffTimer?.cancel();
            _autoOffTimer = Timer(const Duration(minutes: 10), () {
              print("NEBULA_BG: RESET_RELAYS");
              final offCmds = {
                'relay1': 0,
                'relay2': 0,
                'relay3': 0,
                'relay4': 0,
                'relay5': 0,
                'relay6': 0,
              };
              database.child(cmdPath).update(offCmds);
              database.child(telemetryPath).update({
                'relay1': false,
                'relay2': false,
                'relay3': false,
                'relay4': false,
                'relay5': false,
                'relay6': false,
              });
            });
          }

          if (isArmed) {
            await flutterLocalNotificationsPlugin.show(
              999,
              '🚨 NEBULA ALARM: $zone',
              'Security breach detected. Grid activated.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelId,
                  'NEBULA CRITICAL ALARM',
                  fullScreenIntent: true,
                  category: AndroidNotificationCategory.alarm,
                  importance: Importance.max,
                  priority: Priority.high,
                  sound: RawResourceAndroidNotificationSound('siren'),
                ),
              ),
            );
          }
        }
      }
    });

    service.on('stopService').listen((event) {
      _autoOffTimer?.cancel();
      service.stopSelf();
    });

    Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "NEBULA SECURITY ACTIVE",
            content: "Neural Grid Powered • Pulse OK",
          );
        }
      }
    });
  }
}
