import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/connection_settings_provider.dart';
import '../../services/haptic_service.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../../providers/performance_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../../core/ui/pill_layout_engine.dart';

class StatusCard extends ConsumerStatefulWidget {
  final double voltage;
  final String systemState;

  const StatusCard({
    super.key,
    required this.voltage,
    required this.systemState,
  });

  @override
  ConsumerState<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  bool _isExpanded = false;
  bool _isPressed = false;
  int _displayIndex = 0;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animationController.addListener(() {
      setState(() {}); // Rebuild for engine values
    });
  }

  void _handleTap() {
    if (!_isExpanded) {
      _isExpanded = true;
      _displayIndex = 1;
      _animationController.forward();
      _startCollapseTimer();
    } else {
      // Cycle views while expanded
      setState(() {
        _displayIndex = (_displayIndex + 1) % 4;
        if (_displayIndex == 0) _displayIndex = 1;
      });
      _startCollapseTimer();
    }
    HapticService.medium();
  }

  void _collapse() {
    if (mounted && _isExpanded) {
      setState(() {
        _isExpanded = false;
        _displayIndex = 0;
      });
      _animationController.reverse();
    }
  }

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 4), _collapse);
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voltageColor = widget.voltage < 100
        ? Colors
              .redAccent // CRITICAL POWER CUT
        : (widget.voltage >= 100 && widget.voltage < 180)
        ? Colors
              .orangeAccent // Low Voltage
        : (widget.voltage >= 180 && widget.voltage < 250)
        ? Colors.greenAccent
        : Colors.redAccent; // Overvoltage

    // Dynamic Island Data
    final switches = ref.watch(switchDevicesProvider);
    final liveInfo = ref.watch(liveInfoProvider);
    final connSettings = ref.watch(connectionSettingsProvider);

    final activeSwitches = switches.where((s) => s.isActive).toList();
    final activeCount = activeSwitches.length;

    // Use Advanced Layout Engine
    final pill = PillLayoutEngine.calculate(
      _animationController.value,
      Responsive.screenWidth,
    );

    return Center(
      child: GestureDetector(
        onTapDown: (_) {
          HapticService.light();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            width: pill.width,
            height: pill.height,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(pill.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: PixelLedBorder(
              borderRadius: pill.radius,
              strokeWidth: 1.5,
              duration: const Duration(seconds: 4),
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
                theme.colorScheme.tertiary,
                theme.colorScheme.primary,
              ],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(pill.radius),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Glow
                      if (!ref.watch(performanceProvider))
                        Positioned.fill(
                          child: Animate(
                            onPlay: (c) => c.repeat(reverse: true),
                            effects: [
                              ShimmerEffect(
                                duration: 5.seconds,
                                color: voltageColor.withOpacity(0.05),
                                angle: 45,
                              ),
                            ],
                            child: Container(color: Colors.transparent),
                          ),
                        ),

                      // Collapsed Content (Fade out as progress increases)
                      Opacity(
                        opacity: pill.collapsedOpacity,
                        child: IgnorePointer(
                          ignoring: _animationController.value > 0.5,
                          child: _buildDefaultView(theme, voltageColor),
                        ),
                      ),

                      // Expanded Content (Fade in as progress increases)
                      Opacity(
                        opacity: pill.expandedOpacity,
                        child: IgnorePointer(
                          ignoring: _animationController.value < 0.5,
                          child:
                              _buildExpandedView(
                                    theme,
                                    activeCount,
                                    activeSwitches,
                                    liveInfo.acVoltage,
                                    liveInfo.temperature,
                                    connSettings.mode,
                                    _displayIndex,
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .scale(
                                    begin: const Offset(0.95, 0.95),
                                    duration: 400.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultView(ThemeData theme, Color voltageColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Background Voltage
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final perf = ref.watch(performanceProvider);
                      final icon = Icon(
                        Icons.bolt_rounded,
                        color: voltageColor,
                        size: 18,
                      );
                      if (perf) return icon;

                      return icon
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1.5.seconds,
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.voltage < 100 ? 'SYSTEM CRITICAL' : 'AC MAIN',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: widget.voltage < 100
                          ? Colors.redAccent
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.voltage < 100
                              ? 'POWER CUT'
                              : widget.voltage.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: widget.voltage < 100 ? 20.sp : 28.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.voltage >= 100) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              'V',
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 3.seconds,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
            ],
          ),

          // Divider
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),

          // Right: System Status
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'STATUS',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .fade(duration: 1.seconds),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.voltage < 100 ? "GRID OFFLINE" : "SYSTEM ACTIVE",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: widget.voltage < 100
                      ? Colors.red
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap for info",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(
    ThemeData theme,
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
    String subLabel = "";

    switch (index) {
      case 1: // Switches
        label = activeCount == 0 ? 'ALL OFF' : '$activeCount ACTIVE';
        subLabel = activeCount == 1
            ? activeSwitches.first.nickname ?? 'Switch'
            : 'Devices Online';
        icon = Icons.power_settings_new_rounded;
        color = activeCount > 0 ? Colors.greenAccent : Colors.grey;
        break;
      case 2: // Weather
        label = '${temp.toInt()}°C TEMP';
        subLabel = 'Room Temperature';
        icon = Icons.thermostat_rounded;
        color = Colors.orangeAccent;
        break;
      case 3: // Network
        label = mode.name.toUpperCase();
        subLabel = "Connection Mode";
        icon = mode == ConnectionMode.cloud
            ? Icons.cloud_done_rounded
            : Icons.wifi_rounded;
        color = Colors.cyanAccent;
        break;
      default:
        label = widget.voltage < 160
            ? 'POWER FAULT'
            : '${voltage.toInt()}V GRID';
        subLabel = widget.voltage < 160 ? "Check Mains" : "Stable Voltage";
        icon = Icons.bolt_rounded;
        color = widget.voltage < 160 ? Colors.red : Colors.yellowAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2.seconds,
              ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0.w,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 3.seconds,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
              Text(
                subLabel,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Dot Indicators to show pages
          Row(
            children: [1, 2, 3].map((i) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == i
                      ? theme.colorScheme.primary
                      : Colors.white.withOpacity(0.1),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
