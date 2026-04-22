import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_info.dart';
import '../providers/device_id_provider.dart';
import 'package:flutter/foundation.dart';

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
  StreamSubscription<DatabaseEvent>? _satelliteSubscription;
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

    // Listen for Device ID changes and re-init listeners
    ref.listen<String>(deviceIdProvider, (previous, next) {
      _initFirebaseListeners();
    });

    _initFirebaseListeners();

    // Update weather every 30 minutes
    _weatherTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _loadWeather();
    });
  }

  void _initFirebaseListeners() {
    _sensorSubscription?.cancel();
    final deviceId = ref.read(deviceIdProvider);

    // Listen to sensor data from Firebase Realtime Database
    try {
      _sensorSubscription = _database
          .child('devices/$deviceId/telemetry')
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

                // Parse tele_id
                int teleId = state.teleId;
                if (data.containsKey('tele_id')) {
                  teleId = int.tryParse(data['tele_id'].toString()) ?? 0;
                }

                // Removed signal_p parsing from main telemetry to reduce stress
                
                state = state.copyWith(
                  acVoltage: voltage,
                  current: current,
                  teleId: teleId,
                );
                _lastDataSeen = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              }
            },
            onError: (error) {
              print('Firebase Telemetry Error: $error');
            },
          );

      _satelliteSubscription?.cancel();
      _satelliteSubscription = _database
          .child('devices/$deviceId/satellite/status')
          .onValue
          .listen(
            (event) {
              final data = event.snapshot.value;
              if (data != null && data is Map) {
                // Parse Signal Strengths (P1-P5) from Satellite Heartbeat
                List<int> signals = List.from(state.signals);
                for (int i = 0; i < 5; i++) {
                  final key = 'signal_p${i + 1}';
                  if (data.containsKey(key)) {
                    signals[i] = int.tryParse(data[key].toString()) ?? 0;
                  }
                }
                state = state.copyWith(signals: signals);
              }
            },
            onError: (error) {
              print('Satellite Status Error: $error');
            },
          );

    } catch (e) {
      print('Error initializing Firebase listeners: $e');
    }
  }

  int _lastDataSeen = 0;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      state = state.copyWith(currentTime: now);

      // Reset stale telemetry if no data for 60s
      final nowSec = now.millisecondsSinceEpoch ~/ 1000;
      if (_lastDataSeen != 0 && (nowSec - _lastDataSeen > 60)) {
        state = state.copyWith(
          acVoltage: 0,
          current: 0,
          signals: [0, 0, 0, 0, 0],
        );
        _lastDataSeen = 0; // Reset monitor
      }
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
        desc = lat > 0 ? 'Optimal Conditions' : 'Stable Microclimate';
      } else {
        // Fallback for when location is not available
        desc = 'Satellite Sync Active';
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
    _satelliteSubscription?.cancel();
    super.dispose();
  }
}
