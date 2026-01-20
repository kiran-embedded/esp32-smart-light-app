import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_constants.dart';
import '../models/switch_schedule.dart';
import 'persistence_service.dart';

class SchedulerService {
  static const int _baseAlarmId = 1000;

  static const _platform = MethodChannel(
    'com.iot.nebulacontroller/native_scheduler',
  );

  /// Initialize the Scheduler service
  static Future<void> init() async {
    // No specific initialization needed for native calls,
    // but we re-register to be safe.
    await reRegisterAll();
  }

  static Future<bool> requestPermissions() async {
    // 1. Exact Alarms (Android 12+) - MANUALLY OPEN SYSTEM SETTINGS
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      log('SCHEDULER: Exact Alarm Status: ${status.name}');
      if (status != PermissionStatus.granted) {
        log(
          'SCHEDULER: Missing Exact Alarm permission. Launching System Intent...',
        );
        try {
          // ACTION_REQUEST_SCHEDULE_EXACT_ALARM
          const intent = AndroidIntent(
            action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
            data: 'package:com.iot.nebulacontroller',
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
        } catch (e) {
          log('SCHEDULER: Failed to launch intent: $e');
          // Fallback to standard request
          await Permission.scheduleExactAlarm.request();
        }
      }
    }

    // 2. Notifications (Android 13+) - So user knows it fired
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 3. Battery Optimizations (Optional - Removed for Play Store Safety)

    return true;
  }

  static Future<PermissionStatus> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    return await Permission.scheduleExactAlarm.status;
  }

  static Future<void> openAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        data: 'package:com.iot.nebulacontroller',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      log('SCHEDULER: Failed to launch manual intent: $e');
      await openAppSettings();
    }
  }

  /// Re-register all enabled schedules (useful on boot/startup)
  static Future<void> reRegisterAll() async {
    final savedSchedules = await PersistenceService.getSchedules();
    for (var data in savedSchedules) {
      final schedule = SwitchSchedule.fromJson(data);
      if (schedule.isEnabled) {
        await scheduleEvent(schedule);
      }
    }
    log('Re-registered ${savedSchedules.length} schedules on startup');
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

    log('Scheduling alarm #$alarmId for ${schedule.targetNode} at $nextTime');

    // Pass data to native Android scheduler
    // The native receiver will handle Firebase logic directly.
    try {
      final String? deviceId = await PersistenceService.getDeviceId();

      await _platform.invokeMethod('schedule', {
        'id': alarmId,
        'time': nextTime.millisecondsSinceEpoch,
        'targetNode': schedule.targetNode,
        'targetState': schedule.targetState,
        'deviceId': deviceId ?? AppConstants.defaultDeviceId,
      });
      log('SCHEDULER: Native Alarm Set Success');
    } catch (e) {
      log('SCHEDULER: Native Scheduling Failed: $e');
    }
  }

  static Future<void> cancelEvent(String scheduleId) async {
    final alarmId = scheduleId.hashCode;
    try {
      await _platform.invokeMethod('cancel', {'id': alarmId});
    } catch (e) {
      log('SCHEDULER: Failed to cancel native alarm: $e');
    }
  }

  /// Execute an immediate command using the Native Foreground Service
  /// Used by Geofencing and other critical triggers.
  static Future<void> executeNativeCommand(String node, bool state) async {
    try {
      final String? deviceId = await PersistenceService.getDeviceId();
      await _platform.invokeMethod('executeAction', {
        'targetNode': node,
        'targetState': state,
        'deviceId': deviceId ?? AppConstants.defaultDeviceId,
      });
      log('SCHEDULER: Native Action Executed -> $node: $state');
    } catch (e) {
      log('SCHEDULER: Native Action Failed: $e');
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

    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    if (schedule.days.isNotEmpty) {
      for (int i = 0; i < 14; i++) {
        if (schedule.days.contains(next.weekday)) {
          return next;
        }
        next = next.add(const Duration(days: 1));
      }
      return null;
    }

    return next;
  }
}
