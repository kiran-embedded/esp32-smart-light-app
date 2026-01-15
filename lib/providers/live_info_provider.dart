import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_info.dart';
import '../core/constants/app_constants.dart';
import '../services/persistence_service.dart';
import 'package:flutter/foundation.dart';

final liveInfoProvider = StateNotifierProvider<LiveInfoNotifier, LiveInfo>((
  ref,
) {
  return LiveInfoNotifier();
});

class LiveInfoNotifier extends StateNotifier<LiveInfo> {
  Timer? _timer;
  Timer? _weatherTimer;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double _voltageOffset = 0.0;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _calibrationSubscription;

  LiveInfoNotifier()
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
    _loadCalibration();
    _startTimer();
    _loadWeather();
    _initFirebaseListeners();
    // Update weather every 30 minutes
    _weatherTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _loadWeather();
    });
  }

  Future<void> _loadCalibration() async {
    // 1. Initial local load
    _voltageOffset = await PersistenceService.getVoltageCalibration();

    // 2. Setup Firebase listener for global sync
    _calibrationSubscription = _database
        .child('settings/voltage_calibration')
        .onValue
        .listen((event) {
          final data = event.snapshot.value;
          if (data != null) {
            final remoteOffset = double.tryParse(data.toString()) ?? 0.0;
            if (remoteOffset != _voltageOffset) {
              _voltageOffset = remoteOffset;
              PersistenceService.saveVoltageCalibration(_voltageOffset);
              if (kDebugMode)
                print('Sync: Remote Calibration Applied: $_voltageOffset');
            }
          }
        });
  }

  Future<void> calibrateVoltage(double expectedVoltage) async {
    final currentReported = state.acVoltage;
    // accurate offset calculation
    _voltageOffset = expectedVoltage - (currentReported - _voltageOffset);

    // Save locally
    await PersistenceService.saveVoltageCalibration(_voltageOffset);

    // Sync to Firebase for all devices
    await _database.child('settings/voltage_calibration').set(_voltageOffset);

    // Immediate update
    state = state.copyWith(acVoltage: expectedVoltage);
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
                // Parse voltage
                double voltage = state.acVoltage;
                if (data.containsKey('voltage')) {
                  double rawVoltage =
                      double.tryParse(data['voltage'].toString()) ?? 0.0;

                  // Apply Calibration
                  voltage = rawVoltage + _voltageOffset;

                  // Mains Cut Logic / Floating Voltage Fix
                  // specific threshold: if voltage < 160, show 0 (Mains Cut)
                  // Also handle negative values just in case
                  if (voltage < 160.0) {
                    voltage = 0.0;
                  }
                }

                // Parse current
                double current = state.current;
                if (data.containsKey('current_amp')) {
                  current =
                      double.tryParse(data['current_amp'].toString()) ?? 0.0;
                }

                // Parse device status
                bool isOnline = state.isDeviceOnline;
                if (data.containsKey('online')) {
                  isOnline = data['online'] == true;
                }

                DateTime? lastSeen = state.deviceLastSeen;
                if (data.containsKey('lastSeen')) {
                  final rawTs = data['lastSeen'];
                  int? ts;
                  if (rawTs is int) {
                    ts = rawTs;
                  } else {
                    ts = int.tryParse(rawTs.toString());
                  }

                  if (ts != null) {
                    lastSeen = DateTime.fromMillisecondsSinceEpoch(ts);
                  }
                }

                state = state.copyWith(
                  acVoltage: voltage,
                  current: current,
                  isDeviceOnline: isOnline,
                  deviceLastSeen: lastSeen,
                );
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
      final now = DateTime.now();
      bool isOnline = state.isDeviceOnline;

      // Heartbeat check: If lastSeen is older than 2 minutes, mark as offline
      if (state.deviceLastSeen != null) {
        final diff = now.difference(state.deviceLastSeen!);
        if (diff.inMinutes >= 2) {
          isOnline = false;
        }
      }

      state = state.copyWith(currentTime: now, isDeviceOnline: isOnline);
    });
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
    _calibrationSubscription?.cancel();
    super.dispose();
  }
}
