import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../providers/switch_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/connection_settings_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/user_activity_service.dart';

class DynamicIslandPill extends ConsumerStatefulWidget {
  const DynamicIslandPill({super.key});

  @override
  ConsumerState<DynamicIslandPill> createState() => _DynamicIslandPillState();
}

class _DynamicIslandPillState extends ConsumerState<DynamicIslandPill> {
  bool _isExpanded = false;
  int _displayIndex =
      0; // 0: Switches, 1: Voltage, 2: System Health, 3: Network
  Timer? _collapseTimer;

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isExpanded) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switches = ref.watch(switchDevicesProvider);
    final liveInfo = ref.watch(liveInfoProvider);
    final connSettings = ref.watch(connectionSettingsProvider);
    final sensorState = ref.watch(userActivityServiceProvider);
    final activeSwitches = switches.where((s) => s.isActive).toList();
    final activeCount = activeSwitches.length;

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (!_isExpanded) {
            _isExpanded = true;
            _displayIndex = 0;
            _startCollapseTimer(); // Start timer on expansion
          } else {
            _displayIndex = (_displayIndex + 1) % 5; // Cycle 5 stats
            _startCollapseTimer(); // Reset timer on interaction
            if (_displayIndex == 0) _isExpanded = false;
          }
        });
        HapticService.selection();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: const Cubic(0.2, 0.9, 0.4, 1.0),
        width: _isExpanded ? 260 : 100, // Compact 100px for iPhone pill look
        height: _isExpanded ? 48 : 32, // Sleek 32px height
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(
            _isExpanded ? 24 : 50,
          ), // Perfect stadium border
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(
              _isExpanded ? 0.5 : 0.3,
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: _isExpanded ? 15 : 10,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Internal Content with CrossFade
            AnimatedCrossFade(
              firstChild: _buildCollapsedContent(activeCount),
              secondChild: _buildExpandedContent(
                activeCount,
                activeSwitches,
                liveInfo.acVoltage,
                liveInfo.temperature,
                connSettings.mode,
                _displayIndex,
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

            // Subtle Shimmer removed for static look
            if (sensorState.isMonitoring)
              Positioned(
                right: _isExpanded ? 16 : 12, // Adjusted for balance
                top: _isExpanded ? 18 : 15,
                child: _buildSensorIndicator(sensorState.isMoving),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(bool isMoving) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFD0054).withOpacity(isMoving ? 0.8 : 0.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFD0054).withOpacity(isMoving ? 0.6 : 0.2),
            blurRadius: isMoving ? 6 : 3,
            spreadRadius: isMoving ? 1 : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent(int activeCount) {
    return Container(
      width: 120,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildConnectivityIcon(), // Connected/Offline Pill
          if (activeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectivityIcon() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final isConnected = (snapshot.data?.snapshot.value as bool?) ?? true;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isConnected ? Colors.green : Colors.red).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            isConnected ? "CONNECTED" : "OFFLINE",
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.greenAccent : Colors.redAccent,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(
    int activeCount,
    List<dynamic> activeSwitches,
    double voltage,
    double temp,
    ConnectionMode mode,
    int index,
  ) {
    String label = "";
    IconData icon = Icons.info_outline_rounded;
    Color color = Colors.white;

    switch (index) {
      case 1:
        label = '${voltage.toInt()}V AC STABLE';
        icon = Icons.bolt_rounded;
        color = voltage < 180 ? Colors.redAccent : Colors.greenAccent;
        break;
      case 2:
        label = '${temp.toInt()}°C WEATHER';
        icon = Icons.cloud_queue_rounded;
        color = temp > 35 ? Colors.orangeAccent : Colors.lightBlueAccent;
        break;
      case 3:
        label = mode.name.toUpperCase() + ' MODE';
        icon = mode == ConnectionMode.cloud
            ? Icons.cloud_done_rounded
            : Icons.wifi_rounded;
        color = Colors.cyanAccent;
        break;
      case 4:
        label = 'SYSTEM HEALTHY';
        icon = Icons.health_and_safety_rounded;
        color = Colors.deepPurpleAccent;
        break;
      default:
        label = activeCount == 0
            ? 'SYSTEM READY'
            : activeCount == 1
            ? activeSwitches.first.nickname ?? activeSwitches.first.name
            : '$activeCount DEVICES ON';
        icon = Icons.power_rounded;
        color = Colors.greenAccent;
    }

    return Container(
      width: 260, // Increased to 260 for full text visibility
      height: 48,
      padding: const EdgeInsets.only(
        left: 12,
        right: 20,
      ), // Optimized padding for text fit
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
          _buildActivityPulse(activeCount > 0),
        ],
      ),
    );
  }

  Widget _buildActivityPulse(bool active) {
    return RepaintBoundary(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.greenAccent : Colors.white10,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
