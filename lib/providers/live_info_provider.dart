import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_info.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

import '../services/local_network_service.dart';
import '../services/connectivity_service.dart'; // Import this
import '../providers/connection_settings_provider.dart'; // Import this if needed for enum

final liveInfoProvider = StateNotifierProvider<LiveInfoNotifier, LiveInfo>((
  ref,
) {
  return LiveInfoNotifier(ref);
});

class LiveInfoNotifier extends StateNotifier<LiveInfo> {
  final Ref ref;
  Timer? _timer;
  Timer? _weatherTimer;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  LiveInfoNotifier(this.ref)
    : super(
        LiveInfo(
          currentTime: DateTime.now(),
          weatherIcon: '☀️',
          temperature: 22.0,
          weatherDescription: 'Sunny',
          acVoltage: 220.0,
          current: 0.0,
        ),
      ) {
    _startTimer();
    _loadWeather();
    _initFirebaseListeners();
    // Update weather every 30 minutes
    _weatherTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _loadWeather();
    });
  }

  void _initFirebaseListeners() {
    // Listen to sensor data from Firebase Realtime Database
    try {
      _sensorSubscription = _database
          .child('devices/${AppConstants.defaultDeviceId}/telemetry')
          .onValue
          .listen(
            (event) {
              final data = event.snapshot.value;
              if (data != null && data is Map) {
                // Parse voltage
                double voltage = state.acVoltage;
                if (data.containsKey('voltage')) {
                  voltage = double.tryParse(data['voltage'].toString()) ?? 0.0;
                }

                // Parse current
                double current = state.current;
                if (data.containsKey('current_amp')) {
                  current =
                      double.tryParse(data['current_amp'].toString()) ?? 0.0;
                }

                state = state.copyWith(acVoltage: voltage, current: current);
              }
            },
            onError: (error) {
              print('Firebase Telemetry Error: $error');
            },
          );
    } catch (e) {
      print('Error initializing Firebase listeners: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(currentTime: DateTime.now());
      _checkLocalVoltage(); // Poll local voltage if applicable
    });
  }

  Future<void> _checkLocalVoltage() async {
    // 1. Check if we are in Local Mode using ConnectivityProvider (or basic check)
    // Since we don't want circular dependency, we can use Ref if possible,
    // or just check LocalNetworkService if it has devices.

    final localService = ref.read(localNetworkServiceProvider);
    if (!localService.hasDiscoveredDevices) return;

    // 2. Poll Status (Every 1s via _timer is fine)
    // We get the first device IP
    // 2. Poll Status (Every 1s via _timer is fine)
    // We get the first device IP

    // Quick fix: iterate values
    // Accessing private map is not possible, so let's rely on service
    // We need a way to get *any* IP.
    // Let's assume setDeviceMode logic: first value.
    // We need a public getter for IP in service.
    // I added `getIp(deviceId)` in previous turn.

    String? targetIp = localService.getIp(AppConstants.defaultDeviceId);

    // If specific ID not found (maybe discovery used partial ID), try fallback?
    // Let's stick to strict ID for now.

    // Actually, localNetworkService has `_discoveredDevices` but no public list.
    // I added `hasDiscoveredDevices`.

    // Let's try to get status from the service directly if I expose a helper.
    // Or just use the known IP if available.
    if (targetIp != null) {
      final data = await localService.getDeviceStatus(targetIp);
      if (data.isNotEmpty && data.containsKey('voltage')) {
        double voltage = double.tryParse(data['voltage'].toString()) ?? 0.0;
        state = state.copyWith(acVoltage: voltage);
      }
    }
  }

  Future<void> _loadWeather() async {
    try {
      double lat = 0;

      // 1. Check Service Status FIRST
      // This prevents Android from asking "Turn on Location" if GPS is off.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          try {
            final pos = await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 5),
            );
            lat = pos.latitude;
          } catch (e) {
            if (kDebugMode) print('Location fetch failed: $e');
          }
        }
      }

      // 2. Fetch Weather (Simulating API hit with location context or fallback)
      final now = DateTime.now();
      final hour = now.hour;

      String icon = 'Sun';
      String desc = 'Clear Sky';
      double temp = 24.5;

      if (hour < 6 || hour >= 19) {
        icon = 'Moon';
        desc = 'Clear Night';
        temp = 21.0;
      } else if (hour >= 14 && hour < 17) {
        icon = 'Sun';
        desc = 'Hot & Sunny';
        temp = 32.0;
      } else if (lat != 0) {
        // Industry Level: Location context
        desc = lat > 0 ? 'Northern Sky' : 'Southern Sky';
      } else {
        // Fallback for "Internet Location" (Simulated)
        desc = 'United States'; // Default or based on timezone if we had it
      }

      state = state.copyWith(
        weatherIcon: icon,
        temperature: temp,
        weatherDescription: desc,
      );
    } catch (e) {
      if (kDebugMode) print('Weather/Location error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weatherTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }
}
