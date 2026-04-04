import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'live_info_provider.dart';

class UsageState {
  final double currentPower; // Watts
  final double totalEnergy; // kWh
  final DateTime lastUpdate;

  UsageState({
    required this.currentPower,
    required this.totalEnergy,
    required this.lastUpdate,
  });

  UsageState copyWith({
    double? currentPower,
    double? totalEnergy,
    DateTime? lastUpdate,
  }) {
    return UsageState(
      currentPower: currentPower ?? this.currentPower,
      totalEnergy: totalEnergy ?? this.totalEnergy,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier(ref);
});

class UsageNotifier extends StateNotifier<UsageState> {
  final Ref ref;
  Timer? _timer;

  UsageNotifier(this.ref)
    : super(
        UsageState(
          currentPower: 0.0,
          totalEnergy: 0.0,
          lastUpdate: DateTime.now(),
        ),
      ) {
    _startTracking();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final liveInfo = ref.read(liveInfoProvider);

      // Calculate real-time power: P = V * I
      final power = liveInfo.acVoltage * liveInfo.current;

      // Calculate energy increment: kWh = (Power in kW) * (Time in hours)
      // Time is 1s = 1/3600 hours
      final increment = (power / 1000.0) * (1.0 / 3600.0);

      state = state.copyWith(
        currentPower: power,
        totalEnergy: state.totalEnergy + increment,
        lastUpdate: DateTime.now(),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
