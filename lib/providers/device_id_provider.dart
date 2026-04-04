import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';
import '../core/constants/app_constants.dart';

final deviceIdProvider = StateNotifierProvider<DeviceIdNotifier, String>((ref) {
  return DeviceIdNotifier();
});

class DeviceIdNotifier extends StateNotifier<String> {
  DeviceIdNotifier() : super(AppConstants.defaultDeviceId) {
    _load();
  }

  Future<void> _load() async {
    final id = await PersistenceService.getDeviceId();
    if (id != null && id.isNotEmpty) {
      state = id;
    }
  }

  Future<void> update(String newId) async {
    if (newId.isEmpty) return;
    state = newId;
    await PersistenceService.saveDeviceId(newId);
  }
}
