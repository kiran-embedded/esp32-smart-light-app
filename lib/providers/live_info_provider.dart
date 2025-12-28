import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/live_info.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

final liveInfoProvider = StateNotifierProvider<LiveInfoNotifier, LiveInfo>((
  ref,
) {
  return LiveInfoNotifier();
});

class LiveInfoNotifier extends StateNotifier<LiveInfo> {
  Timer? _timer;
  Timer? _weatherTimer;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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
    super.dispose();
  }
}
