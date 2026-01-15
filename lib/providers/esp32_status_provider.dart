import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';

enum Esp32Status {
  active,
  offline,
  error,
  connecting,
}

class Esp32StatusState {
  final Esp32Status status;
  final DateTime? lastSeen;
  final String? errorMessage;
  final double? lastVoltage;

  Esp32StatusState({
    this.status = Esp32Status.connecting,
    this.lastSeen,
    this.errorMessage,
    this.lastVoltage,
  });

  Esp32StatusState copyWith({
    Esp32Status? status,
    DateTime? lastSeen,
    String? errorMessage,
    double? lastVoltage,
  }) {
    return Esp32StatusState(
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      errorMessage: errorMessage ?? this.errorMessage,
      lastVoltage: lastVoltage ?? this.lastVoltage,
    );
  }
}

final esp32StatusProvider =
    StateNotifierProvider<Esp32StatusNotifier, Esp32StatusState>((ref) {
  return Esp32StatusNotifier();
});

class Esp32StatusNotifier extends StateNotifier<Esp32StatusState> {
  StreamSubscription<DatabaseEvent>? _telemetrySubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  Timer? _timeoutTimer;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Esp32StatusNotifier() : super(Esp32StatusState()) {
    _initListeners();
  }

  void _initListeners() {
    // Listen to Firebase connection status
    _connectionSubscription = _database
        .child('.info/connected')
        .onValue
        .listen((event) {
      final isConnected = (event.snapshot.value as bool?) ?? false;
      if (!isConnected) {
        state = state.copyWith(
          status: Esp32Status.offline,
          errorMessage: 'Firebase disconnected',
        );
        _resetTimeout();
        return;
      }
    });

    // Listen to ESP32 telemetry (non-blocking)
    _telemetrySubscription = _database
        .child('devices/${AppConstants.defaultDeviceId}/telemetry')
        .onValue
        .listen(
      (event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          final voltage = double.tryParse(data['voltage']?.toString() ?? '0') ?? 0.0;
          
          state = state.copyWith(
            status: Esp32Status.active,
            lastSeen: DateTime.now(),
            lastVoltage: voltage,
            errorMessage: null,
          );
          _resetTimeout();
        } else {
          // No data but connection exists - might be connecting
          if (state.status == Esp32Status.offline) {
            state = state.copyWith(status: Esp32Status.connecting);
          }
        }
      },
      onError: (error) {
        state = state.copyWith(
          status: Esp32Status.error,
          errorMessage: error.toString(),
        );
        _resetTimeout();
      },
    );

    // Timeout check - if no telemetry for 30 seconds, mark as offline
    _resetTimeout();
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (state.status == Esp32Status.active || state.status == Esp32Status.connecting) {
        final now = DateTime.now();
        final lastSeen = state.lastSeen;
        if (lastSeen == null ||
            now.difference(lastSeen).inSeconds > 30) {
          state = state.copyWith(
            status: Esp32Status.offline,
            errorMessage: 'No telemetry received',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _connectionSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}


