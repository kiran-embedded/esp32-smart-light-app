import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/ble_service.dart';
import '../providers/connection_settings_provider.dart';

class ConnectivityState {
  final String? ssid;
  final bool isEspHotspot;
  final bool isLocalReachable;
  final bool isFirebaseConnected;
  final ConnectionMode activeMode;

  ConnectivityState({
    this.ssid,
    this.isEspHotspot = false,
    this.isLocalReachable = false,
    this.isFirebaseConnected = false,
    this.activeMode = ConnectionMode.cloud,
  });

  ConnectivityState copyWith({
    String? ssid,
    bool? isEspHotspot,
    bool? isLocalReachable,
    bool? isFirebaseConnected,
    ConnectionMode? activeMode,
  }) {
    return ConnectivityState(
      ssid: ssid ?? this.ssid,
      isEspHotspot: isEspHotspot ?? this.isEspHotspot,
      isLocalReachable: isLocalReachable ?? this.isLocalReachable,
      isFirebaseConnected: isFirebaseConnected ?? this.isFirebaseConnected,
      activeMode: activeMode ?? this.activeMode,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Ref _ref;
  final _networkInfo = NetworkInfo();
  Timer? _pollingTimer;
  StreamSubscription? _firebaseSub;

  ConnectivityNotifier(this._ref) : super(ConnectivityState()) {
    _init();
  }

  void _init() {
    _firebaseSub = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) {
          final connected = (event.snapshot.value as bool?) ?? false;
          _updateStatus(isFirebaseConnected: connected);

          // CRITICAL: If Firebase drops, immediately try to find Local Device
          if (!connected) {
            print("⚠️ Firebase Disconnected - Ensuring BLE Scan...");
            _ref.read(bleServiceProvider).initBLE();
            _checkConnectivity();
          }
        });

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    String? ssid;
    try {
      ssid = await _networkInfo.getWifiName();
      if (ssid != null && ssid.startsWith('"') && ssid.endsWith('"')) {
        ssid = ssid.substring(1, ssid.length - 1);
      }
    } catch (_) {}

    final isEspHotspot =
        ssid != null && ssid.contains('Nebula'); // Matches new AP SSID or old

    final bleService = _ref.read(bleServiceProvider);
    bool isLocalReachable = bleService.isConnected;

    if (!isLocalReachable && !state.isFirebaseConnected) {
      // Passive attempt to connect BLE if everything is down
      bleService.initBLE();
    }

    _updateStatus(
      ssid: ssid,
      isEspHotspot: isEspHotspot,
      isLocalReachable:
          isLocalReachable, // This flag might need refinement based on exact device ping
    );
  }

  void _updateStatus({
    String? ssid,
    bool? isEspHotspot,
    bool? isLocalReachable,
    bool? isFirebaseConnected,
  }) {
    final newState = state.copyWith(
      ssid: ssid,
      isEspHotspot: isEspHotspot,
      isLocalReachable: isLocalReachable,
      isFirebaseConnected: isFirebaseConnected,
    );

    final settings = _ref.read(connectionSettingsProvider);
    ConnectionMode activeMode = settings.mode;

    // DYNAMIC SWITCHING LOGIC
    // DYNAMIC SWITCHING LOGIC
    // STRICT MODE: Active mode is simply the user-selected mode
    // No more auto-switching magic.
    if (activeMode != settings.mode) {
      activeMode = settings.mode;
    }

    state = newState.copyWith(activeMode: activeMode);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _firebaseSub?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier(ref);
    });
