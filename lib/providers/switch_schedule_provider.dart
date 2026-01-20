import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/switch_schedule.dart';
import '../core/constants/app_constants.dart';
import '../services/persistence_service.dart';
import '../services/scheduler_service.dart';

class SwitchScheduleNotifier extends StateNotifier<List<SwitchSchedule>> {
  StreamSubscription? _subscription;
  final _database = FirebaseDatabase.instance.ref();

  SwitchScheduleNotifier() : super([]) {
    _loadLocal();
    _initListener();
  }

  Future<void> _loadLocal() async {
    final localData = await PersistenceService.getSchedules();
    if (localData.isNotEmpty) {
      state = localData.map((e) => SwitchSchedule.fromJson(e)).toList();
    }
  }

  void _initListener() {
    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules';
    _subscription = _database.child(path).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        // Only clear if we receive an explicit null (empty) from initialized firebase
        // Use caution to not wipe local data if offline (though onValue usually implies sync)
        if (state.isNotEmpty) {
          // Verify if this is a genuine empty list from server
          state = [];
          PersistenceService.saveSchedules([]);
        }
        return;
      }

      final List<SwitchSchedule> schedules = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            schedules.add(
              SwitchSchedule.fromJson(Map<String, dynamic>.from(value)),
            );
          } catch (e) {
            print('Error parsing schedule: $e');
          }
        }
      });

      // Update state and local storage
      state = schedules;
      PersistenceService.saveSchedules(
        schedules.map((e) => e.toJson()).toList(),
      );
    });
  }

  Future<void> addSchedule(SwitchSchedule schedule) async {
    // Optimistic Update
    state = [...state, schedule];
    PersistenceService.saveSchedules(state.map((e) => e.toJson()).toList());

    // Schedule Background Job
    await SchedulerService.scheduleEvent(schedule);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/${schedule.id}';
    await _database.child(path).set(schedule.toJson());
  }

  Future<void> updateSchedule(SwitchSchedule schedule) async {
    // Optimistic Update
    state = [
      for (final s in state)
        if (s.id == schedule.id) schedule else s,
    ];
    PersistenceService.saveSchedules(state.map((e) => e.toJson()).toList());

    // Update Background Job
    await SchedulerService.scheduleEvent(schedule);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/${schedule.id}';
    await _database.child(path).update(schedule.toJson());
  }

  Future<void> deleteSchedule(String id) async {
    // Optimistic Update
    state = state.where((s) => s.id != id).toList();
    PersistenceService.saveSchedules(state.map((e) => e.toJson()).toList());

    // Cancel Background Job
    await SchedulerService.cancelEvent(id);

    final path =
        '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/$id';
    await _database.child(path).remove();
  }

  Future<void> deleteSchedules(List<String> ids) async {
    // Optimistic Update
    state = state.where((s) => !ids.contains(s.id)).toList();
    PersistenceService.saveSchedules(state.map((e) => e.toJson()).toList());

    for (final id in ids) {
      // Cancel Background Job
      await SchedulerService.cancelEvent(id);

      final path =
          '${AppConstants.firebaseDevicesPath}/${AppConstants.defaultDeviceId}/schedules/$id';
      await _database.child(path).remove();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final switchScheduleProvider =
    StateNotifierProvider<SwitchScheduleNotifier, List<SwitchSchedule>>((ref) {
      return SwitchScheduleNotifier();
    });
