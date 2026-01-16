import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic; // Relay Control (Write)
  BluetoothCharacteristic? _txCharacteristic; // Status (Notify)

  final String _targetDeviceName = "NEBULA";
  final String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _rxUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String _txUuid = "cba1d466-344c-4be3-ab31-107001af753d";

  bool _isConnecting = false;
  bool _isInitialized = false;
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  Timer? _backgroundScanTimer;
  StreamSubscription? _scanSubscription;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  Future<void> initBLE() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Request Permissions first
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (status[Permission.bluetoothScan] != PermissionStatus.granted ||
        status[Permission.bluetoothConnect] != PermissionStatus.granted) {
      print("❌ BLE Permissions Denied");
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      print("❌ BLE: Not supported on this device");
      return;
    }

    // Monitor Adapter State
    FlutterBluePlus.adapterState.listen((state) {
      print("📡 BLE Adapter State: $state");
      if (state == BluetoothAdapterState.on) {
        _startScanCycle();
      }
    });

    // Scan listener
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      _scanResultsController.add(results);
      if (results.isNotEmpty) {
        print("🔍 BLE: Scanned ${results.length} total devices");
      }

      for (ScanResult r in results) {
        String deviceName = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.localName;

        if (deviceName.isNotEmpty) {
          print(
            "  - Found: $deviceName [RSSI: ${r.rssi}] ID: ${r.device.remoteId}",
          );
        }

        bool nameMatch =
            deviceName.isNotEmpty &&
            deviceName.toUpperCase().contains(_targetDeviceName.toUpperCase());

        bool uuidMatch = r.advertisementData.serviceUuids.contains(
          Guid(_serviceUuid),
        );

        if ((nameMatch || uuidMatch) &&
            !_isConnecting &&
            _connectedDevice == null) {
          print(
            "✨ BLE: Target Match Found! Name: '$deviceName', UUID Match: $uuidMatch",
          );
          _connectToDevice(r.device);
        }
      }
    });

    // Start periodic background re-scan
    _backgroundScanTimer?.cancel();
    _backgroundScanTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectedDevice == null && !_isConnecting) {
        print("🔍 [BleService] Periodic Background Scan Triggered...");
        _startScanCycle();
      }
    });
  }

  Future<void> _startScanCycle() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        print("🔍 [BleService] Scan already in progress, skipping start.");
        return;
      }
      print("🔍 [BleService] Starting Scan (15s timeout)...");
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true, // Force high accuracy for discovery
      );
    } catch (e) {
      print("❌ [BleService] Scan Error: $e");
    }
  }

  Future<void> startManualScan() async {
    print("🔍 [BleService] Manual Scan Requested...");
    if (await FlutterBluePlus.isSupported == false) return;
    try {
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print("❌ [BleService] Manual Scan Error: $e");
    }
  }

  Future<void> manualConnect(BluetoothDevice device) async {
    _connectToDevice(device);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;

    // Stop scanning once we start connecting
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}

    try {
      print("🔗 Connecting to ${device.remoteId}...");
      await device.connect(
        autoConnect: true,
        timeout: const Duration(seconds: 15),
      );
      _connectedDevice = device;

      // Listen for disconnection
      device.connectionState.listen((connectionState) {
        if (connectionState == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _rxCharacteristic = null;
          _txCharacteristic = null;
          print("⚠️ BLE Disconnected. Restarting scan...");
          _startScanCycle();
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            _serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            String uuid = char.uuid.toString().toLowerCase();
            if (uuid == _rxUuid.toLowerCase()) _rxCharacteristic = char;
            if (uuid == _txUuid.toLowerCase()) _txCharacteristic = char;
          }
        }
      }
      print("✅ Connected to NEBULA via BLE");
    } catch (e) {
      print("❌ BLE Connection Error: $e");
      _isConnecting = false;
      // If connection fails, resume scanning
      _startScanCycle();
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> sendCommand(int index, bool state) async {
    if (_rxCharacteristic == null) {
      return false;
    }

    try {
      // Format: [Index, State]
      await _rxCharacteristic!.write([
        index,
        state ? 1 : 0,
      ], withoutResponse: false);
      return true;
    } catch (e) {
      print("BLE Command Failed: $e");
      return false;
    }
  }

  bool get isConnected => _connectedDevice != null;

  void dispose() {
    _backgroundScanTimer?.cancel();
    _scanSubscription?.cancel();
    _scanResultsController.close();
  }
}

final bleServiceProvider = Provider((ref) {
  final service = BleService();
  return service;
});
