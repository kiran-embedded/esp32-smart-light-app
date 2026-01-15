import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

class UpdateState {
  final UpdateInfo? updateInfo;
  final bool isChecking;
  final bool hasNotified;
  final bool isLaterSelected;

  UpdateState({
    this.updateInfo,
    this.isChecking = false,
    this.hasNotified = false,
    this.isLaterSelected = false,
  });

  UpdateState copyWith({
    UpdateInfo? updateInfo,
    bool? isChecking,
    bool? hasNotified,
    bool? isLaterSelected,
  }) {
    return UpdateState(
      updateInfo: updateInfo ?? this.updateInfo,
      isChecking: isChecking ?? this.isChecking,
      hasNotified: hasNotified ?? this.hasNotified,
      isLaterSelected: isLaterSelected ?? this.isLaterSelected,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService;

  UpdateNotifier(this._updateService) : super(UpdateState());

  Future<void> checkForUpdates() async {
    state = state.copyWith(isChecking: true);
    final info = await _updateService.checkUpdate();
    state = state.copyWith(updateInfo: info, isChecking: false);
  }

  void markNotified() {
    state = state.copyWith(hasNotified: true);
  }

  void setLater() {
    state = state.copyWith(isLaterSelected: true);
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((
  ref,
) {
  final service = ref.watch(updateServiceProvider);
  return UpdateNotifier(service);
});
