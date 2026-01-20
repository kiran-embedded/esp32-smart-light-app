import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/geofence_rule.dart';
import '../services/persistence_service.dart';
import '../services/geofence_service.dart';

final geofenceProvider =
    StateNotifierProvider<GeofenceNotifier, List<GeofenceRule>>((ref) {
      return GeofenceNotifier();
    });

class GeofenceNotifier extends StateNotifier<List<GeofenceRule>> {
  GeofenceNotifier() : super([]) {
    _loadRules();
  }

  Future<void> _loadRules() async {
    final savedRules = await PersistenceService.getGeofenceRules();
    state = savedRules.map((e) => GeofenceRule.fromJson(e)).toList();
  }

  Future<void> addRule(GeofenceRule rule) async {
    state = [...state, rule];
    await _saveToPersistence();
    await NebulaGeofenceService.refreshRules();
  }

  Future<void> updateRule(GeofenceRule rule) async {
    state = [
      for (final r in state)
        if (r.id == rule.id) rule else r,
    ];
    await _saveToPersistence();
    await NebulaGeofenceService.refreshRules();
  }

  Future<void> deleteRules(List<String> ids) async {
    state = state.where((r) => !ids.contains(r.id)).toList();
    await _saveToPersistence();

    // Explicitly remove from Native Layer
    for (final id in ids) {
      await NebulaGeofenceService.removeRule(id);
    }
  }

  Future<void> _saveToPersistence() async {
    await PersistenceService.saveGeofenceRules(
      state.map((e) => e.toJson()).toList(),
    );
  }
}
