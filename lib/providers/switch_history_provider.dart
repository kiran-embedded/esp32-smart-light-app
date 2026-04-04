import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/switch_history.dart';

class SwitchHistoryNotifier extends StateNotifier<List<SwitchHistoryEvent>> {
  final String deviceId;

  SwitchHistoryNotifier(this.deviceId) : super([]) {
    _listenToLogs();
  }

  void _listenToLogs() {
    final ref = FirebaseDatabase.instance.ref('devices/$deviceId/logs');
    try {
      ref.keepSynced(true);
    } catch (_) {}

    // Listen to the last 50 events
    ref.orderByChild('timestamp').limitToLast(50).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        state = [];
        return;
      }

      final List<SwitchHistoryEvent> logs = [];
      data.forEach((key, value) {
        logs.add(SwitchHistoryEvent.fromJson(Map<String, dynamic>.from(value)));
      });

      // Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = logs;
    });
  }
}

final switchHistoryProvider =
    StateNotifierProvider.family<
      SwitchHistoryNotifier,
      List<SwitchHistoryEvent>,
      String
    >((ref, deviceId) {
      return SwitchHistoryNotifier(deviceId);
    });
