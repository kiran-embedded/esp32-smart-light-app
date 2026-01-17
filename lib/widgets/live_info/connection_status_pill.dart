import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/animation_provider.dart';
import '../../services/connectivity_service.dart';
import '../../providers/connection_settings_provider.dart';
import '../../providers/live_info_provider.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../../core/ui/responsive_layout.dart';

class ConnectionStatusPill extends ConsumerStatefulWidget {
  const ConnectionStatusPill({super.key});

  @override
  ConsumerState<ConnectionStatusPill> createState() =>
      _ConnectionStatusPillState();
}

class _ConnectionStatusPillState extends ConsumerState<ConnectionStatusPill> {
  int _infoIndex = 0;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    _startCycleTimer();
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startCycleTimer() {
    _cycleTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _infoIndex = (_infoIndex + 1) % 3; // Cycle through 3 states
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectivity = ref.watch(connectivityProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final liveInfo = ref.watch(liveInfoProvider);
    final animations = ref.watch(animationSettingsProvider);
    final animationsEnabled = animations.animationsEnabled;

    final themeColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary,
    ];

    final pScale = displaySettings.pillScale;
    final fScale = displaySettings.fontSize;

    // Determine Status Logic based on ConnectivityProvider
    String modeText;
    Color statusColor;
    IconData statusIcon;
    bool isConnected = false;
    String voltageText = "${liveInfo.acVoltage.toStringAsFixed(0)}V";

    if (connectivity.activeMode == ConnectionMode.cloud) {
      if (connectivity.isFirebaseConnected) {
        modeText = "CLOUD MODE";
        statusColor = Colors.greenAccent;
        statusIcon = Icons.cloud_done_rounded;
        isConnected = true;
      } else {
        modeText = "CONNECTING...";
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.cloud_sync_rounded;
        isConnected = false;
      }
    } else {
      // Local Mode
      if (connectivity.isEspHotspot) {
        modeText = "HOTSPOT MODE";
        statusColor = Colors.purpleAccent;
        statusIcon = Icons.wifi_tethering;
        isConnected = true;
      } else if (connectivity.isLocalReachable) {
        modeText = "LOCAL MODE";
        statusColor = Colors.cyanAccent; // User requested Blueish for local
        statusIcon = Icons.wifi;
        isConnected = true;
      } else {
        // Fallback or searching in Local Mode
        modeText = "SCANNING...";
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.wifi_find;
        isConnected = false;
      }
    }

    // Override if completely disconnected (no SSID and no Firebase)
    if (connectivity.ssid == null &&
        !connectivity.isFirebaseConnected &&
        !connectivity.isLocalReachable) {
      modeText = "DISCONNECTED";
      statusColor = Colors.redAccent;
      statusIcon = Icons.signal_wifi_off;
      isConnected = false;
    }

    // Determine Display Text based on Cycle
    String displayText;
    if (!isConnected) {
      displayText = modeText; // Always show error/status if not connected
    } else {
      switch (_infoIndex) {
        case 0:
          displayText = modeText;
          break;
        case 1:
          displayText = "ESP32 ACTIVE";
          break;
        case 2:
          displayText = isConnected ? "VOLTAGE: $voltageText" : modeText;
          break;
        default:
          displayText = modeText;
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // DYNAMIC LED FLASH BACKGROUND
        _buildLedGlow(
          statusColor,
          isConnected,
          isConnected,
          pScale,
          animationsEnabled,
        ),

        Container(
          margin: EdgeInsets.only(
            top:
                (16.h * pScale).toDouble() + MediaQuery.of(context).padding.top,
          ),
          child: PixelLedBorder(
            borderRadius: (30 * pScale).toDouble(),
            strokeWidth: (1.5 * pScale).toDouble(),
            duration: const Duration(seconds: 4),
            colors: themeColors,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: (16.w * pScale).toDouble(),
                vertical: (8.h * pScale).toDouble(),
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular((30 * pScale).toDouble()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Sync Indicator with small LED dot
                  _buildAppSyncDot(
                    isConnected,
                    theme,
                    pScale,
                    fScale,
                    animationsEnabled,
                  ),
                  SizedBox(width: (12.w * pScale).toDouble()),

                  // Main Status Icon
                  Icon(
                        statusIcon,
                        color: statusColor,
                        size: (16.sp * fScale * pScale).toDouble(),
                      )
                      .animate(
                        onPlay: (c) => c.repeat(),
                        autoPlay: animationsEnabled,
                      )
                      .shimmer(
                        duration: 2.seconds,
                        color: Colors.white.withOpacity(0.5),
                      ),

                  SizedBox(width: (8.w * pScale).toDouble()),

                  // Status Text (Animated Switcher)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      displayText,
                      key: ValueKey<String>(displayText),
                      style: GoogleFonts.outfit(
                        fontSize: (10.sp * fScale * pScale).toDouble(),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: statusColor,
                      ),
                    ),
                  ),

                  SizedBox(width: (8.w * pScale).toDouble()),
                  _buildStatusIndicator(statusColor, pScale, animationsEnabled),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedGlow(
    Color color,
    bool appOk,
    bool devOk,
    double scale,
    bool animationsEnabled,
  ) {
    return Positioned(
      child:
          Container(
                width: (160.w * scale).toDouble(),
                height: (40.h * scale).toDouble(),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular((30 * scale).toDouble()),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: (20 * scale).toDouble(),
                      spreadRadius: (5 * scale).toDouble(),
                    ),
                  ],
                ),
              )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
                autoPlay: animationsEnabled,
              )
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: (appOk && devOk) ? 2.seconds : 500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1.seconds),
    );
  }

  Widget _buildStatusIndicator(
    Color color,
    double scale,
    bool animationsEnabled,
  ) {
    return Container(
          width: (5.w * scale).toDouble(),
          height: (5.w * scale).toDouble(),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: (6 * scale).toDouble(),
                spreadRadius: (1 * scale).toDouble(),
              ),
            ],
          ),
        )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
          autoPlay: animationsEnabled,
        )
        .fade(begin: 0.3, end: 1.0, duration: 800.ms);
  }

  Widget _buildAppSyncDot(
    bool isConnected,
    ThemeData theme,
    double pScale,
    double fScale,
    bool animationsEnabled,
  ) {
    return Container(
      padding: EdgeInsets.all((4.w * pScale).toDouble()),
      decoration: BoxDecoration(
        color: (isConnected ? Colors.blueAccent : Colors.grey).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isConnected ? Colors.blueAccent : Colors.grey).withOpacity(
            0.3,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.cloud_sync_rounded,
            size: (10.sp * fScale * pScale).toDouble(),
            color: isConnected ? Colors.blueAccent : Colors.grey,
          ),
          if (isConnected)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: (3.w * pScale).toDouble(),
                height: (3.w * pScale).toDouble(),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat()).fade(duration: 400.ms),
            ),
        ],
      ),
    );
  }
}
