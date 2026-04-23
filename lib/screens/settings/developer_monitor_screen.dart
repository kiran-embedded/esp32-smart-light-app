import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import '../../providers/device_id_provider.dart';
import '../../providers/security_provider.dart';

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
  StreamSubscription? _satSub;
  StreamSubscription? _logSub;

  Map<dynamic, dynamic> _telemetryData = {};
  Map<dynamic, dynamic> _satTelemetry = {};
  List<Map<dynamic, dynamic>> _logs = [];

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

    _satSub = _db.child('devices/$deviceId/security/nodeActive').onValue.listen((
      event,
    ) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _satTelemetry = event.snapshot.value as Map<dynamic, dynamic>;
        });
      }
    });

    _logSub = _db
        .child('devices/$deviceId/security/logs')
        .orderByChild('ts')
        .limitToLast(30)
        .onValue
        .listen((event) {
          if (mounted && event.snapshot.value != null) {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
            final List<Map<dynamic, dynamic>> sortedLogs = data.entries.map((
              e,
            ) {
              return e.value as Map<dynamic, dynamic>;
            }).toList();
            sortedLogs.sort((a, b) {
              final tsA = (a['ts'] as num?)?.toInt() ?? 0;
              final tsB = (b['ts'] as num?)?.toInt() ?? 0;
              return tsB.compareTo(tsA);
            });
            setState(() {
              _logs = sortedLogs;
            });
          }
        });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _satSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }

  void _forceResync() {
    final deviceId = ref.read(deviceIdProvider);
    _db.child('devices/$deviceId/commands/sync').set(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SENDING SYSTEM SYNC COMMAND...'),
        backgroundColor: Colors.cyanAccent,
      ),
    );
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isOnline = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isOnline
                    ? Colors.greenAccent.withOpacity(0.3)
                    : Colors.redAccent.withOpacity(0.3),
              ),
            ),
            child: Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeter(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndustrialCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final bool isHubOnline = securityState.isHubOnline;
    final bool isSatOnline = securityState.isSatOnline;

    final num hubHeap = (_telemetryData['heap'] as num?) ?? 0;
    final num hubLatency = (_telemetryData['latency'] as num?) ?? 0;
    final String hubIp = _telemetryData['ip']?.toString() ?? 'N/A';
    final int hubRssi = (_telemetryData['rssi'] as num?)?.toInt() ?? -100;
    final String hubUptime = _telemetryData['uptime']?.toString() ?? '0';

    final String satVersion = _satTelemetry['version']?.toString() ?? 'N/A';
    final int satRssi = (_satTelemetry['signal'] as num?)?.toInt() ?? -100;

    final double hubHeapPct = (hubHeap / 320000).clamp(0.0, 1.0);
    final double hubLatencyPct = (hubLatency / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      appBar: AppBar(
        title: const Text(
          'INDUSTRIAL TELEMETRY',
          style: TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 2.0,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.cyanAccent,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _logs.clear()),
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white38,
              size: 20,
            ),
          ),
          TextButton(
            onPressed: _forceResync,
            child: const Text(
              'SYNC',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildSectionHeader('NEBULA_HUB_01', isOnline: isHubOnline),
            _buildIndustrialCard([
              Row(
                children: [
                  Expanded(
                    child: _buildMeter(
                      'RAM_USAGE',
                      1.0 - hubHeapPct,
                      Colors.lightGreenAccent,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildMeter(
                      'CPU_LATENCY',
                      hubLatencyPct,
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDataRow('IP_ADDR', hubIp, Colors.cyanAccent),
              _buildDataRow(
                'FREE_RAM',
                '${hubHeap.toInt()} BYTES',
                Colors.white70,
              ),
              _buildDataRow('UPTIME', '${hubUptime}s', Colors.white54),
              _buildDataRow(
                'WIFI_SIG',
                '$hubRssi dBm',
                hubRssi > -70 ? Colors.greenAccent : Colors.teal,
              ),
              _buildDataRow(
                'LOOP_PACE',
                '${hubLatency.toInt()}ms',
                hubLatency < 30 ? Colors.greenAccent : Colors.redAccent,
              ),
            ]),
            _buildSectionHeader('SATELLITE_NODE_01', isOnline: isSatOnline),
            _buildIndustrialCard([
              Row(
                children: [
                  Expanded(
                    child: _buildMeter(
                      'SYS_HEALTH',
                      isSatOnline ? 1.0 : 0.0,
                      isSatOnline ? Colors.lightGreenAccent : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildMeter(
                      'WIFI_LINK',
                      1.0 - ((satRssi.abs() - 30) / 70).clamp(0.0, 1.0),
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDataRow('FIRMWARE', satVersion, Colors.cyanAccent),
              _buildDataRow(
                'WIFI_SIG',
                '$satRssi dBm',
                satRssi > -70 ? Colors.greenAccent : Colors.teal,
              ),
              _buildDataRow('SYNC_NODE', 'ESP8266_PIR_ARRAY', Colors.white54),
            ]),
            _buildSectionHeader('CLOUD_SYSLOG_STREAM'),
            Container(
              height: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.white.withOpacity(0.02), height: 1),
                itemBuilder: (context, i) {
                  final log = _logs[i];
                  final String source = log['source'] == 'HUB'
                      ? '[HUB]'
                      : '[SAT]';
                  return Text(
                    '$source ${log['msg'] ?? '...'}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color:
                          (log['source'] == 'HUB'
                                  ? Colors.cyanAccent
                                  : Colors.orangeAccent)
                              .withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
