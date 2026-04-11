import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';
import '../services/persistence_service.dart';

class NeuralLogicState {
  final Map<int, List<int>>
  pirMap; // PIR Index (0-4) -> List of Relay Indices (0-6)
  final int pirTimer;
  final bool isLoading;

  NeuralLogicState({
    this.pirMap = const {
      0: [0],
      1: [1],
      2: [2],
      3: [3],
      4: [4],
    },
    this.pirTimer = 60,
    this.isLoading = false,
  });

  NeuralLogicState copyWith({
    Map<int, List<int>>? pirMap,
    int? pirTimer,
    bool? isLoading,
  }) {
    return NeuralLogicState(
      pirMap: pirMap ?? this.pirMap,
      pirTimer: pirTimer ?? this.pirTimer,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final neuralLogicProvider =
    StateNotifierProvider<NeuralLogicNotifier, NeuralLogicState>((ref) {
      return NeuralLogicNotifier();
    });

class NeuralLogicNotifier extends StateNotifier<NeuralLogicState> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription? _subscription;
  String _deviceId = AppConstants.defaultDeviceId;

  NeuralLogicNotifier() : super(NeuralLogicState()) {
    _init();
  }

  Future<void> _init() async {
    final savedId = await PersistenceService.getDeviceId();
    if (savedId != null) _deviceId = savedId;
    _listenToMapping();
  }

  void _listenToMapping() {
    _subscription?.cancel();
    _subscription = _database
        .child('devices/$_deviceId/commands')
        .onValue
        .listen((event) {
          final data = event.snapshot.value;
          if (data is Map) {
            final newMap = Map<int, List<int>>.from(state.pirMap);

            for (int i = 1; i <= 5; i++) {
              final key = 'mapPIR$i';
              if (data.containsKey(key)) {
                final val = data[key];
                if (val is num) {
                  final int bitmask = val.toInt();
                  final relays = <int>[];
                  for (int r = 0; r < 7; r++) {
                    if ((bitmask & (1 << r)) != 0) {
                      relays.add(r);
                    }
                  }
                  newMap[i - 1] = relays;
                }
              }
            }

            if (data.containsKey('pirTimer')) {
              final val = data['pirTimer'];
              if (val is num && state.pirTimer != val.toInt()) {
                state = state.copyWith(pirTimer: val.toInt());
              }
            }

            // Deep comparison for map change
            bool mapChanged = false;
            if (newMap.length != state.pirMap.length) {
              mapChanged = true;
            } else {
              for (var entry in newMap.entries) {
                final current = state.pirMap[entry.key];
                if (current == null ||
                    current.length != entry.value.length ||
                    !current.every((e) => entry.value.contains(e))) {
                  mapChanged = true;
                  break;
                }
              }
            }

            if (mapChanged) {
              state = state.copyWith(pirMap: newMap);
            }
          }
        });
  }

  Future<void> updateTimer(int seconds) async {
    await _database.child('devices/$_deviceId/commands').update({
      'pirTimer': seconds,
    });
    state = state.copyWith(pirTimer: seconds);
  }

  Future<void> toggleLink(int pirIndex, int relayIndex) async {
    final currentRelays = List<int>.from(state.pirMap[pirIndex] ?? []);
    if (currentRelays.contains(relayIndex)) {
      currentRelays.remove(relayIndex);
    } else {
      currentRelays.add(relayIndex);
    }

    int bitmask = 0;
    for (var r in currentRelays) {
      bitmask |= (1 << r);
    }

    final key = 'mapPIR${pirIndex + 1}';
    await _database.child('devices/$_deviceId/commands').update({key: bitmask});

    // Optimistic update
    final newMap = Map<int, List<int>>.from(state.pirMap);
    newMap[pirIndex] = currentRelays;
    state = state.copyWith(pirMap: newMap);
  }

  Future<void> clearMapping(int pirIndex) async {
    final key = 'mapPIR${pirIndex + 1}';
    await _database.child('devices/$_deviceId/commands').update({
      key: 0,
    }); // 0 mask = all unlinked

    final newMap = Map<int, List<int>>.from(state.pirMap);
    newMap[pirIndex] = [];
    state = state.copyWith(pirMap: newMap);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
