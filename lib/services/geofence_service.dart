import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../models/geofence_rule.dart';
import 'persistence_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_constants.dart';

class NebulaGeofenceService {
  static const MethodChannel _channel = MethodChannel(
    'com.iot.nebulacontroller/native_scheduler',
  );

  static Future<void> init() async {
    // Re-register all rules on app start to ensure native client is fresh
    await refreshRules();
  }

  static Future<bool> requestPermissions() async {
    // 1. Request Foreground Location first (req for Always)
    final fgStatus = await Permission.location.request();
    if (!fgStatus.isGranted) return false;

    // 2. Request Always Location
    final bgStatus = await Permission.locationAlways.request();
    if (bgStatus.isGranted) {
      // 3. Request battery optimization ignore
      await Permission.ignoreBatteryOptimizations.request();
      // 4. Request Notifications (for executor service)
      await Permission.notification.request();
    }
    return bgStatus.isGranted;
  }

  static Future<void> refreshRules() async {
    final savedRules = await PersistenceService.getGeofenceRules();
    final rules = savedRules.map((e) => GeofenceRule.fromJson(e)).toList();

    // Loop through rules and register them natively
    final deviceId =
        await PersistenceService.getDeviceId() ?? AppConstants.defaultDeviceId;

    for (final rule in rules) {
      if (!rule.isEnabled) {
        // Ensure disabled rules are removed native side
        await removeRule(rule.id);
        continue;
      }

      try {
        await _channel.invokeMethod(
          'addGeofence',
          rule.toJson()..addAll({'deviceId': deviceId}),
        );
        log('Registered Native Geofence: ${rule.id}');
      } on PlatformException catch (e) {
        log('Failed to register native geofence: ${e.message}');
      }
    }
  }

  static Future<void> addRule(GeofenceRule rule) async {
    try {
      final deviceId =
          await PersistenceService.getDeviceId() ??
          AppConstants.defaultDeviceId;
      await _channel.invokeMethod(
        'addGeofence',
        rule.toJson()..addAll({'deviceId': deviceId}),
      );
      log('Added Native Geofence: ${rule.id}');
    } on PlatformException catch (e) {
      log('Failed to add native geofence: ${e.message}');
    }
  }

  static Future<void> removeRule(String id) async {
    try {
      await _channel.invokeMethod('removeGeofence', {'id': id});
      log('Removed Native Geofence: $id');
    } on PlatformException catch (e) {
      log('Failed to remove native geofence: ${e.message}');
    }
  }
}
