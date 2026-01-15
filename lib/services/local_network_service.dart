import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

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

  Future<void> startDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;

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

  // Fallback: Scan common subnet IPs if mDNS fails (Android often blocks mDNS)
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

  // Helper to send command
  Future<bool> sendLocalCommand(
    String deviceId,
    int relayIndex,
    bool state,
  ) async {
    String? ip = _discoveredDevices[deviceId];

    // FALLBACK: If specific ID not found, use ANY discovered IP (Single Device Assumption)
    if (ip == null && _discoveredDevices.isNotEmpty) {
      ip = _discoveredDevices.values.first;
      print('LocalCommand: ID $deviceId not found, using fallback IP $ip');
    }

    if (ip == null) {
      print(
        'LocalCommand: No IP found for $deviceId and no devices discovered.',
      );
      return false;
    }

    try {
      final url = Uri.parse(
        'http://$ip/set?relay=${relayIndex + 1}&state=${state ? 1 : 0}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      print('Local Command Failed: $e');
      return false; // Fallback to Cloud will be handled by provider
    }
  }

  // Get voltage/status
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    String? ip = _discoveredDevices[deviceId];

    // Fallback IP for status check too
    if (ip == null && _discoveredDevices.isNotEmpty) {
      ip = _discoveredDevices.values.first;
    }

    if (ip == null) return null;

    try {
      final response = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Direct IP override for Hotspot or Fixed IP
  void setDirectIp(String deviceId, String ip) {
    _discoveredDevices[deviceId] = ip;
  }

  String? getIp(String deviceId) => _discoveredDevices[deviceId];
}

final localNetworkServiceProvider = Provider((ref) => LocalNetworkService());
