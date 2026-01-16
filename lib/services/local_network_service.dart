import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

class LocalDevice {
  final String ip;
  final int port;
  final String id;

  LocalDevice({required this.ip, required this.port, required this.id});
}

class LocalNetworkService {
  final MDnsClient _mdns = MDnsClient();
  bool _isScanning = false;

  // Cache discovered devices: Map<DeviceId, IP>
  final Map<String, String> _discoveredDevices = {};

  // Persistent Client for lower latency
  final http.Client _client = http.Client();

  Future<void> startSmartDiscovery({bool force = false}) async {
    // Prevent redundant scans if devices found or already scanning
    if (_isScanning) return;
    if (!force && _discoveredDevices.isNotEmpty) return;

    _isScanning = true;

    // 1. Start mDNS (Parallel)
    _startMdnsDiscovery();

    // 2. Start Subnet Scan (Parallel)
    _startSubnetScan();
  }

  Future<void> _startMdnsDiscovery() async {
    try {
      await _mdns.start();

      // Look for _nebula._tcp service
      await for (final PtrResourceRecord ptr in _mdns.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_nebula._tcp.local'),
      )) {
        await for (final SrvResourceRecord srv
            in _mdns.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )) {
          await for (final IPAddressResourceRecord ip
              in _mdns.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )) {
            print('Device found at ${ip.address}:${srv.port}');

            // Temporary ID mapping if we don't have TXT records yet
            // Ideally we'd parse TXT for deviceId, or just treat IP as the key resource
            // For now, let's verify it's a nebula device by hitting /status
            _verifyAndAddDevice(ip.address.address);
          }
        }
      }
    } catch (e) {
      print('mDNS Error: $e');
    } finally {
      _mdns.stop();
      _isScanning = false;
    }
  }

  Future<void> _startSubnetScan() async {
    try {
      final info = NetworkInfo();
      String? wifiIp = await info.getWifiIP();
      if (wifiIp != null) {
        String subnet = wifiIp.substring(0, wifiIp.lastIndexOf('.'));
        print("🔍 Scanning Subnet: $subnet.*");
        await aggressiveSubnetScan(subnet);
      }
    } catch (e) {
      print("Subnet Scan Error: $e");
    }
  }

  // Fallback: Scan common subnet IPs
  Future<void> aggressiveSubnetScan(String subnet) async {
    // subnet example: "192.168.1"
    List<Future> futures = [];
    for (int i = 2; i < 255; i++) {
      futures.add(_checkIp("$subnet.$i"));
    }
    await Future.wait(futures);
  }

  Future<void> _checkIp(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(milliseconds: 200));
      if (response.statusCode == 200) {
        _verifyAndAddDevice(ip);
      }
    } catch (_) {}
  }

  Future<void> _verifyAndAddDevice(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String deviceId = data['deviceId']; // e.g., "A1B2C3"

        _discoveredDevices[deviceId] = ip;
        print('✅ Verified Nebula Device: $deviceId @ $ip');
      }
    } catch (e) {
      print('Failed to verify device at $ip: $e');
    }
  }

  // Send Command to Local Device (Ultra Fast)
  Future<void> sendLocalCommand(String ip, int relayIndex, bool state) async {
    try {
      final url = Uri.parse(
        'http://$ip/relay?ch=${relayIndex + 1}&state=${state ? 1 : 0}',
      );
      // Use persistent client for warm connection
      await _client.get(url).timeout(const Duration(milliseconds: 500));
    } catch (e) {
      print("Local Command Error: $e");
      // If persistent client fails, it might need reset? Usually robust.
    }
  }

  Future<Map<String, dynamic>> getDeviceStatus(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Status Fetch Error: $e");
    }
    return {};
  }

  // Direct IP override for Hotspot or Fixed IP
  void setDirectIp(String deviceId, String ip) {
    _discoveredDevices[deviceId] = ip;
  }

  String? getIp(String deviceId) => _discoveredDevices[deviceId];

  // Getter for the first available IP (for single-device setup)
  String? get anyIp => _discoveredDevices.values.isNotEmpty
      ? _discoveredDevices.values.first
      : null;

  bool get hasDiscoveredDevices => _discoveredDevices.isNotEmpty;

  Future<bool> setDeviceMode(String mode) async {
    String? ip = _discoveredDevices.values.isNotEmpty
        ? _discoveredDevices.values.first
        : null;

    if (ip != null) {
      try {
        final url = Uri.parse('http://$ip/mode?value=$mode');
        await http.get(url).timeout(const Duration(seconds: 2));
        return true;
      } catch (e) {
        print("Mode Set Error: $e");
      }
    }

    // Fallback AP IP
    try {
      await http
          .get(Uri.parse('http://192.168.4.1/mode?value=$mode'))
          .timeout(const Duration(milliseconds: 500));
      return true;
    } catch (_) {}

    return false;
  }
}

final localNetworkServiceProvider = Provider((ref) => LocalNetworkService());
