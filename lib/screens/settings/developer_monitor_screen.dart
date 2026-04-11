import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import '../../providers/device_id_provider.dart';

class DeveloperMonitorScreen extends ConsumerStatefulWidget {
  const DeveloperMonitorScreen({super.key});

  @override
  ConsumerState<DeveloperMonitorScreen> createState() =>
      _DeveloperMonitorScreenState();
}

class _DeveloperMonitorScreenState
    extends ConsumerState<DeveloperMonitorScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  StreamSubscription? _telemetrySub;
  Map<dynamic, dynamic> _telemetryData = {};

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    final deviceId = ref.read(deviceIdProvider);
    _telemetrySub = _db.child('devices/$deviceId/telemetry').onValue.listen((
      event,
    ) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _telemetryData = event.snapshot.value as Map<dynamic, dynamic>;
        });
      }
    });

    _db.child('devices/$deviceId/security/masterLDR').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _telemetryData['masterLDR'] = event.snapshot.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF000000);
    const cardColor = Color(0xFF0A0A0A);

    final String ldr = _telemetryData['masterLDR']?.toString() ?? 'N/A';
    final String voltage = _telemetryData['voltage']?.toString() ?? '0.0';
    final String heap = _telemetryData['heap']?.toString() ?? 'N/A';
    final String channel = _telemetryData['ch']?.toString() ?? 'N/A';
    final String isNight = _telemetryData['isNight']?.toString() ?? 'false';
    final String hubMac = _telemetryData['hubMac']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'INDUSTRIAL CONSOLE',
          style: TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 2.0,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.cyanAccent,
          ),
        ),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HUB TELEMETRY STREAM',
              style: TextStyle(
                color: Colors.white24,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildDataRow(
                    'BRIDGE STATUS',
                    _telemetryData.isNotEmpty ? 'ESTABLISHED' : 'WAITING...',
                    _telemetryData.isNotEmpty
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDataRow(
                    'CORE VOLTAGE',
                    '${voltage}V AC',
                    Colors.cyanAccent,
                  ),
                  _buildDataRow(
                    'AVAILABLE HEAP',
                    '${heap} BYTES',
                    Colors.lightGreenAccent,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDataRow('MASTER LDR LEVEL', ldr, Colors.yellowAccent),
                  _buildDataRow(
                    'NIGHT ACTIVATION',
                    isNight.toUpperCase(),
                    isNight == 'true'
                        ? Colors.purpleAccent
                        : Colors.orangeAccent,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDataRow('RADIO CHANNEL', channel, Colors.white),
                  _buildDataRow(
                    'HUB MAC ADDR',
                    hubMac.toUpperCase(),
                    Colors.white24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GRID RELAY MATRIX',
              style: TextStyle(
                color: Colors.white24,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(7, (i) {
                final state = _telemetryData['relay${i + 1}'] ?? 0;
                return Container(
                  width: 80,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state == 1
                        ? Colors.cyanAccent.withOpacity(0.1)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state == 1
                          ? Colors.cyanAccent.withOpacity(0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'R${i + 1}',
                        style: TextStyle(
                          color: state == 1
                              ? Colors.cyanAccent
                              : Colors.white24,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state == 1 ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: state == 1 ? Colors.white : Colors.white10,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'HEX BUFFER DUMP',
              style: TextStyle(
                color: Colors.white24,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                _telemetryData.toString(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
