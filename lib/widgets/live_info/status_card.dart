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

class _StatusCardState extends ConsumerState<StatusCard> {
  bool _isExpanded = false;
  bool _isPressed = false;
  int _displayIndex =
      0; // 0: Voltage+Status (Default), 1: Switches, 2: System Health, 3: Network
  Timer? _collapseTimer;

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isExpanded) {
        setState(() {
          _isExpanded = false;
          _displayIndex = 0; // Reset to default view when collapsing
        });
      }
    });
  }

  void _handleTap() {
    setState(() {
      if (!_isExpanded) {
        _isExpanded = true;
        _displayIndex = 1; // Start showing info
        _startCollapseTimer();
      } else {
        // If already expanded, cycle through views
        _displayIndex = (_displayIndex + 1) % 4;
        if (_displayIndex == 0) _displayIndex = 1; // Skip 0 while expanded
        _startCollapseTimer(); // Reset timer on interaction
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
    final theme = Theme.of(context);
    final voltageColor = widget.voltage < 160
        ? Colors
              .redAccent // CRITICAL LOW VOLTAGE
        : (widget.voltage > 200 && widget.voltage < 250)
        ? Colors.greenAccent
        : (widget.voltage > 250 ? Colors.redAccent : Colors.tealAccent);

    // Dynamic Island Data
    final switches = ref.watch(switchDevicesProvider);
    final liveInfo = ref.watch(liveInfoProvider);
    final connSettings = ref.watch(connectionSettingsProvider);

    final activeSwitches = switches.where((s) => s.isActive).toList();
    final activeCount = activeSwitches.length;

    return Center(
      child: GestureDetector(
        onTapDown: (_) {
          HapticService.light(); // Immediate smooth feedback on touch
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticService.medium(); // Smooth "thud" for the action
          _handleTap();
        },
        child: Animate(
          onPlay: (c) => c.repeat(reverse: true),
          effects: [
            if (!ref.watch(performanceProvider))
              ScaleEffect(
                begin: const Offset(1, 1),
                end: const Offset(1.015, 1.015),
                duration: 3.seconds,
                curve: Curves.easeInOutSine,
              ),
          ],
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0, // Subtler squish
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 450,
              ), // Slower, more fluid expansion
              curve: Curves.fastLinearToSlowEaseIn, // Liquid-like physics
              width: Responsive.screenWidth * 0.90, // Slightly narrower
              height: _isExpanded ? 135.h : 72.h, // Reduced height (was 150/75)
              decoration: BoxDecoration(
                color: Colors.transparent, // Handled by inner container
                borderRadius: BorderRadius.circular(_isExpanded ? 40 : 36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: PixelLedBorder(
                borderRadius: _isExpanded ? 40 : 36,
                strokeWidth: 1.5, // Thinner border
                duration: const Duration(seconds: 4),
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  theme.colorScheme.primary, // Wrap
                ],
                enableInfiniteRainbow: false,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isExpanded ? 40 : 36),
                  child: Container(
                    color: Colors.black, // Opaque Background
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Subtle Glow (Very faint)
                        Positioned.fill(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final perf = ref.watch(performanceProvider);
                              if (perf) return const SizedBox.shrink();

                              return Animate(
                                onPlay: (c) => c.repeat(reverse: true),
                                effects: [
                                  ShimmerEffect(
                                    duration: 5.seconds,
                                    color: voltageColor.withOpacity(0.05),
                                    angle: 45,
                                  ),
                                ],
                                child: Container(color: Colors.transparent),
                              );
                            },
                          ),
                        ),

                        // Content Crossfade
                        AnimatedCrossFade(
                          firstChild: SizedBox(
                            height: 72.h,
                            child: _buildDefaultView(theme, voltageColor),
                          ),
                          secondChild: SizedBox(
                            height: 135.h,
                            child: _buildExpandedView(
                              theme,
                              activeCount,
                              activeSwitches,
                              liveInfo.acVoltage,
                              liveInfo.temperature,
                              connSettings.mode,
                              _displayIndex,
                            ),
                          ),
                          crossFadeState: !_isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 400),
                          sizeCurve: Curves.fastLinearToSlowEaseIn,
                        ),
                      ],
                    ),
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
                    widget.voltage < 160 ? 'MAINS POWER CUT' : 'AC MAIN',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: widget.voltage < 160
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
                          widget.voltage.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
                widget.voltage < 160 ? "CRITICAL ALERT" : "SYSTEM ACTIVE",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: widget.voltage < 160
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
