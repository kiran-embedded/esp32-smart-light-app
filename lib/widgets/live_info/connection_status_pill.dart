import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/display_settings_provider.dart';
import '../../services/connectivity_service.dart';
import '../../providers/connection_settings_provider.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../../core/ui/responsive_layout.dart';

class ConnectionStatusPill extends ConsumerWidget {
  const ConnectionStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectivity = ref.watch(connectivityProvider);
    final displaySettings = ref.watch(displaySettingsProvider);

    final themeColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary,
    ];

    final pScale = displaySettings.pillScale;
    final fScale = displaySettings.fontSize;

    // Determine Status Logic based on ConnectivityProvider
    String statusText;
    Color statusColor;
    IconData statusIcon;
    bool isConnected = false;

    if (connectivity.activeMode == ConnectionMode.cloud) {
      if (connectivity.isFirebaseConnected) {
        statusText = "CLOUD ONLINE";
        statusColor = Colors.greenAccent;
        statusIcon = Icons.cloud_done_rounded;
        isConnected = true;
      } else {
        statusText = "CONNECTING...";
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.cloud_sync_rounded;
        isConnected = false;
      }
    } else {
      // Local Mode
      if (connectivity.isEspHotspot) {
        statusText = "HOTSPOT MODE";
        statusColor = Colors.purpleAccent;
        statusIcon = Icons.wifi_tethering;
        isConnected = true;
      } else if (connectivity.isLocalReachable) {
        statusText = "LOCAL SYSTEM";
        statusColor = Colors.cyanAccent;
        statusIcon = Icons.lan;
        isConnected = true;
      } else {
        // In auto mode, if we fell back to local but can't find device
        statusText = "SEARCHING...";
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.wifi_find_rounded;
        isConnected = false;
      }
    }

    // Override if completely disconnected (no SSID and no Firebase)
    if (connectivity.ssid == null && !connectivity.isFirebaseConnected) {
      statusText = "DISCONNECTED";
      statusColor = Colors.redAccent;
      statusIcon = Icons.signal_wifi_off;
      isConnected = false;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // DYNAMIC LED FLASH BACKGROUND
        _buildLedGlow(statusColor, isConnected, isConnected, pScale),

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
            enableInfiniteRainbow: false,
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
                  _buildAppSyncDot(isConnected, theme, pScale, fScale),
                  SizedBox(width: (12.w * pScale).toDouble()),

                  // Main Status Icon
                  Icon(
                        statusIcon,
                        color: statusColor,
                        size: (16.sp * fScale * pScale).toDouble(),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 2.seconds,
                        color: Colors.white.withOpacity(0.5),
                      ),

                  SizedBox(width: (8.w * pScale).toDouble()),

                  // Status Text
                  Text(
                    statusText,
                    style: GoogleFonts.outfit(
                      fontSize: (10.sp * fScale * pScale).toDouble(),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: statusColor,
                    ),
                  ),

                  SizedBox(width: (8.w * pScale).toDouble()),
                  _buildStatusIndicator(statusColor, pScale),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedGlow(Color color, bool appOk, bool devOk, double scale) {
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
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: (appOk && devOk) ? 2.seconds : 500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: 1.seconds),
    );
  }

  Widget _buildStatusIndicator(Color color, double scale) {
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
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.3, end: 1.0, duration: 800.ms);
  }

  Widget _buildAppSyncDot(
    bool isConnected,
    ThemeData theme,
    double pScale,
    double fScale,
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
