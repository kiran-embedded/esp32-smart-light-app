import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';
import '../models/switch_schedule.dart';
import 'persistence_service.dart';

class SchedulerService {
  static const int _baseAlarmId = 1000;

  /// Initialize the Alarm Manager service
  static Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedule an alarm for a specific switch event
  static Future<void> scheduleEvent(SwitchSchedule schedule) async {
    if (!schedule.isEnabled) {
      await cancelEvent(schedule.id);
      return;
    }

    // Determine the next occurrence of this schedule
    final nextTime = _getNextOccurrence(schedule);
    if (nextTime == null) return;

    // Use hashCode of ID as alarm ID to be unique & reproducible
    final alarmId = schedule.id.hashCode;

    // Retrieve Custom Firebase Config (if any)
    final fbConfig = await PersistenceService.getFirebaseConfig();

    log('Scheduling alarm #$alarmId for ${schedule.relayId} at $nextTime');

    await AndroidAlarmManager.oneShotAt(
      nextTime,
      alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      params: {
        'relayId': schedule.relayId,
        'targetState': schedule.targetState,
        'firebaseConfig': fbConfig, // Pass config to isolate
      },
    );
  }

  static Future<void> cancelEvent(String scheduleId) async {
    final alarmId = scheduleId.hashCode;
    await AndroidAlarmManager.cancel(alarmId);
  }

  /// The static callback that runs in the background isolate
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic> params) async {
    // CRITICAL: Ensure binding is initialized in the background isolate
    WidgetsFlutterBinding.ensureInitialized();
    log('Alarm #$id fired! Params: $params');

    try {
      if (Firebase.apps.isEmpty) {
        // We MUST re-initialize everything in the background isolate
        try {
          final config = params['firebaseConfig'] as Map<dynamic, dynamic>?;

          if (config != null) {
            // Custom Initialization
            await Firebase.initializeApp(
              options: FirebaseOptions(
                apiKey: config['apiKey'],
                appId: config['appId'],
                messagingSenderId: config['messagingSenderId'],
                projectId: config['projectId'],
                databaseURL: config['databaseURL'],
              ),
            );
          } else {
            // Default Initialization (fallback)
            await Firebase.initializeApp();
          }
        } catch (e) {
          log('Background Firebase init failed: $e');
        }
      }

      // 2. Authenticate (Mimic User Action / "Key Press")
      // Without this, database writes fail if rules require auth != null
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        try {
          await auth.signInAnonymously();
          log(
            'Background Auth: Signed in anonymously as ${auth.currentUser?.uid}',
          );
        } catch (e) {
          log('Background Auth Error: $e');
        }
      }

      final String relayId = params['relayId'];
      final bool targetState = params['targetState'];

      // Write to Firebase
      // Path: devices/{deviceId}/commands/{relayId}
      // Protocol: 0 = ON (Active), 1 = OFF (Inactive) - Active Low
      final ref = FirebaseDatabase.instance.ref();
      final path =
          '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/commands';

      // Convert boolean active state to Active-Low integer
      final int commandValue = targetState ? 0 : 1;

      // Update the specific relay key under commands
      await ref.child(path).update({relayId: commandValue});
      log(
        'Successfully updated $relayId to $targetState (Command: $commandValue)',
      );
    } catch (e) {
      log('SCHEDULER ERROR: $e');
    }
  }

  static DateTime? _getNextOccurrence(SwitchSchedule schedule) {
    final now = DateTime.now();
    DateTime next = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );

    // If time has passed today, move to tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    // If specific days are selected, find the next matching day
    // Days format: 1=Mon, ..., 7=Sun
    if (schedule.days.isNotEmpty) {
      // Limit search to 14 days to prevent infinite loops
      for (int i = 0; i < 14; i++) {
        // weekday is 1-7 (Mon-Sun)
        if (schedule.days.contains(next.weekday)) {
          return next;
        }
        next = next.add(const Duration(days: 1));
      }
      return null;
    }

    // If no days specified (daily), just return the calculated next time
    return next;
  }
}
