import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/pixel_led_border.dart'; // Import PixelLedBorder
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/switch_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/connection_settings_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/user_activity_service.dart';
import '../../providers/display_settings_provider.dart';
import '../../core/ui/responsive_layout.dart'; // Added for .r extension

class DynamicIslandPill extends ConsumerStatefulWidget {
  const DynamicIslandPill({super.key});

  @override
  ConsumerState<DynamicIslandPill> createState() => _DynamicIslandPillState();
}

class _DynamicIslandPillState extends ConsumerState<DynamicIslandPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

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
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switches = ref.watch(switchDevicesProvider);
    final liveInfo = ref.watch(liveInfoProvider);
    final connSettings = ref.watch(connectionSettingsProvider);
    final sensorState = ref.watch(userActivityServiceProvider);
    final displaySettings = ref.watch(displaySettingsProvider);

    // Base dimensions multiplied by scale
    final double scale = displaySettings.pillScale;
    final double expandedWidth = 260.0 * scale;
    final double collapsedWidth = 100.0 * scale;
    final double height = (_isExpanded ? 48.0 : 32.0) * scale;
    final double radius = (_isExpanded ? 24.0 : 50.0) * scale;

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
      child: AnimatedBuilder(
        animation: _breathController,
        builder: (context, child) {
          // Replaced existing Border/Shadow logic with PixelLedBorder
          // Theme Colors (Blended)
          final themeColors = [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
            theme.colorScheme.primary, // Wrap
          ];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: const Cubic(0.2, 0.9, 0.4, 1.0),
            width: _isExpanded ? expandedWidth : collapsedWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black, // Solid Black Body
              borderRadius: BorderRadius.circular(radius),
              // NO Border or Shadow here, handled by PixelLedBorder
            ),
            child: PixelLedBorder(
              isStatic: false, // ALWAYS MOVING
              enableInfiniteRainbow: false, // Use Theme Colors
              colors: themeColors,
              borderRadius: radius,
              strokeWidth: 1.5 * scale, // Thinner border
              duration: const Duration(seconds: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Internal Content with CrossFade
                  AnimatedCrossFade(
                    firstChild: _buildCollapsedContent(
                      activeCount,
                      scale,
                      displaySettings.fontSize,
                    ),
                    secondChild: _buildExpandedContent(
                      activeCount,
                      activeSwitches,
                      liveInfo.acVoltage,
                      liveInfo.temperature,
                      connSettings.mode,
                      _displayIndex,
                      scale,
                      displaySettings.fontSize,
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),

                  // Subtle Sensor Indicator
                  if (sensorState.isMonitoring)
                    Positioned(
                      right: _isExpanded ? 16.r : 12.r, // Adjusted for balance
                      top: _isExpanded ? 18.r : 15.r,
                      child: _buildSensorIndicator(sensorState.isMoving),
                    ),
                ],
              ),
            ),
          );
        },
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

  Widget _buildCollapsedContent(int activeCount, double pScale, double fScale) {
    return Container(
      width: (120 * pScale).toDouble(),
      height: (36 * pScale).toDouble(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildConnectivityIcon(pScale, fScale), // Connected/Offline Pill
          if (activeCount > 0) ...[
            SizedBox(width: (8 * pScale).toDouble()),
            Container(
              width: (4 * pScale).toDouble(),
              height: (4 * pScale).toDouble(),
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

  Widget _buildConnectivityIcon(double pScale, double fScale) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final isConnected = (snapshot.data?.snapshot.value as bool?) ?? true;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: (8 * pScale).toDouble(),
            vertical: (2 * pScale).toDouble(),
          ),
          decoration: BoxDecoration(
            color: (isConnected ? Colors.green : Colors.red).withOpacity(0.2),
            borderRadius: BorderRadius.circular((12 * pScale).toDouble()),
            border: Border.all(
              color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
              width: (1 * pScale).toDouble(),
            ),
          ),
          child: Text(
            isConnected ? "CONNECTED" : "OFFLINE",
            style: GoogleFonts.outfit(
              fontSize: (9 * fScale * pScale).toDouble(),
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
    double pScale,
    double fScale,
  ) {
    String label = "";
    IconData icon = Icons.info_outline_rounded;
    Color color = Colors.white;

    switch (index) {
      case 1:
        if (voltage < 180) {
          label = 'MAINS CUT OFF';
          icon = Icons.power_off_rounded;
          color = Colors.redAccent;
        } else {
          label = '${voltage.toInt()}V AC STABLE';
          icon = Icons.bolt_rounded;
          color = Colors.greenAccent;
        }
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
      width: (260 * pScale)
          .toDouble(), // Increased to 260 for full text visibility
      height: (48 * pScale).toDouble(),
      padding: EdgeInsets.only(
        left: (12 * pScale).toDouble(),
        right: (20 * pScale).toDouble(),
      ), // Optimized padding for text fit
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: (16 * fScale * pScale).toDouble(), color: color),
          SizedBox(width: (10 * pScale).toDouble()),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: (11 * fScale * pScale).toDouble(),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2.w,
              ),
            ),
          ),
          const Spacer(),
          _buildActivityPulse(activeCount > 0, pScale),
        ],
      ),
    );
  }

  Widget _buildActivityPulse(bool active, double pScale) {
    return RepaintBoundary(
      child: Container(
        width: (8 * pScale).toDouble(),
        height: (8 * pScale).toDouble(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.greenAccent : Colors.white10,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: (4 * pScale).toDouble(),
                    spreadRadius: (1 * pScale).toDouble(),
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
