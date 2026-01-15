import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/connection_settings_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'local_network_service.dart';

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
            print("⚠️ Firebase Disconnected - Triggering Local Discovery...");
            // Give it a moment to ensure network stack is ready
            Future.delayed(const Duration(milliseconds: 500), () {
              // Assuming we can get the provider container ref here or pass it?
              // _ref is available.
              _ref.read(localNetworkServiceProvider).startDiscovery();
              _checkConnectivity();
            });
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
    String? localIp;
    try {
      ssid = await _networkInfo.getWifiName();
      if (ssid != null && ssid.startsWith('"') && ssid.endsWith('"')) {
        ssid = ssid.substring(1, ssid.length - 1);
      }
      localIp = await _networkInfo.getWifiIP();
    } catch (_) {}

    final isEspHotspot =
        ssid != null && ssid.contains('Nebula'); // Matches new AP SSID or old

    // --- LOCAL DISCOVERY ---
    final localService = _ref.read(localNetworkServiceProvider);
    bool isLocalReachable = false;

    // 1. If we are in Hotspot mode, we know the IP is 192.168.4.1 usually
    if (isEspHotspot) {
      localService.setDirectIp("hotspot_fallback", "192.168.4.1");
      // Try to verify
      final status = await localService.getDeviceStatus(
        "hotspot_fallback",
      ); // ID might differ but IP is key
      if (status != null) isLocalReachable = true;
    }
    // 2. If valid WiFi, try Scan
    else if (localIp != null) {
      // Start mDNS scan
      localService.startDiscovery();

      // Also try aggressive subnet scan if we haven't found anything yet
      // Extract subnet: 192.168.1.50 -> 192.168.1
      final parts = localIp.split('.');
      if (parts.length == 4 && !isLocalReachable) {
        final subnet = "${parts[0]}.${parts[1]}.${parts[2]}";
        // Run in background so we don't block
        localService.aggressiveSubnetScan(subnet).then((_) {
          // Maybe verify specifically if user has devices
        });
      }

      // Just check if ANY device is found
      // In a real multi-device app, we'd check specific IDs.
      // For now, let's assume if we found ANY IP, we have local access.
      // (Or query a known device ID if we had persistent storage of IDs)
    }

    // Check if we have at least one reachable device
    // This is a simplification; ideally we track reachability Per-Device.
    // But for the global "Connectivity Status", we'll say local is reachable if we found something.
    // For now, let's rely on the SWITCH PROVIDER to determine reachability per action.
    // Here we just update general network status.

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
    if (settings.mode == ConnectionMode.auto) {
      // User Request: "when it have internet we use firebase cloud way when no internet in modem we use local way"
      // Firebase Connected Status is a proxy for "Has Internet"
      if (newState.isFirebaseConnected) {
        activeMode = ConnectionMode.cloud;
      } else {
        // Fallback to Local if Cloud is unreachable (No Internet / Modem Mode)
        activeMode = ConnectionMode.local;
      }

      // Refined: If we have Local Access (LAN), PREFER IT over Cloud?
      // Usually Cloud is slower. So:
      // If (LocalReachable) -> Local
      // Else If (CloudReachable) -> Cloud
      // For this step, we need to know if the SPECIFIC device is reachable.
      // Since this is a global status, let's default to Cloud unless we are sure about Local.
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
