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
import '../../core/ui/responsive_layout.dart';

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
        width: _isExpanded
            ? (DisplayEngine.screenW * 0.9).clamp(280.0, 420.0)
            : 125.w, // Dynamic Width based on screen
        height: _isExpanded ? 52.h : 36.h, // Slightly taller for better touch
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(
            _isExpanded ? 24.r : 50.r,
          ), // Perfect stadium border
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(
              _isExpanded ? 0.5 : 0.3,
            ),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: (_isExpanded ? 15 : 10).r,
              spreadRadius: 1.r,
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
                right: (_isExpanded ? 16 : 12).w, // Adjusted for balance
                top: (_isExpanded ? 18 : 15).h,
                child: _buildSensorIndicator(sensorState.isMoving),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(bool isMoving) {
    return Container(
      width: 5.r,
      height: 5.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFD0054).withOpacity(isMoving ? 0.8 : 0.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFD0054).withOpacity(isMoving ? 0.6 : 0.2),
            blurRadius: (isMoving ? 6 : 3).r,
            spreadRadius: isMoving ? 1.r : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent(int activeCount) {
    return Container(
      width: 125.w,
      height: 36.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildConnectivityIcon(), // Connected/Offline Pill
          if (activeCount > 0) ...[
            SizedBox(width: 8.w),
            Container(
              width: 4.r,
              height: 4.r,
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: (isConnected ? Colors.green : Colors.red).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
              width: 1.w,
            ),
          ),
          child: Text(
            isConnected ? "CONNECTED" : "OFFLINE",
            style: GoogleFonts.outfit(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.greenAccent : Colors.redAccent,
              letterSpacing: 0.5.w,
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
        label = voltage < 160 ? 'MAINS CUT' : '${voltage.toInt()}V AC STABLE';
        icon = Icons.bolt_rounded;
        color = voltage < 160 ? Colors.redAccent : Colors.greenAccent;
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
        // Priority Override: If Mains Cut, show it on default view too
        if (voltage < 160) {
          label = 'MAINS CUT';
          icon = Icons.bolt_rounded;
          color = Colors.redAccent;
        } else {
          label = activeCount == 0
              ? 'SYSTEM READY'
              : activeCount == 1
              ? activeSwitches.first.nickname ?? activeSwitches.first.name
              : '$activeCount DEVICES ON';
          icon = Icons.power_rounded;
          color = Colors.greenAccent;
        }
    }

    return Container(
      width: (DisplayEngine.screenW * 0.9).clamp(280.0, 420.0),
      height: 52.h,
      padding: EdgeInsets.only(
        left: 12.w,
        right: 20.w,
      ), // Optimized padding for text fit
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2.w,
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
        width: 8.r,
        height: 8.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.greenAccent : Colors.white10,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 4.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
