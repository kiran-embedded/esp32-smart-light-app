import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/connection_settings_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/common/pixel_led_border.dart';
import '../../core/ui/responsive_layout.dart';

class ConnectionStatusPill extends ConsumerWidget {
  const ConnectionStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveInfo = ref.watch(liveInfoProvider);

    final themeColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary,
    ];

    final connectivityState = ref.watch(connectivityProvider);
    final activeMode = connectivityState.activeMode;
    final displaySettings = ref.watch(displaySettingsProvider);
    final pScale = displaySettings.pillScale;
    final fScale = displaySettings.fontSize;

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final isAppConnected = (snapshot.data?.snapshot.value as bool?) ?? true;
        final isDeviceOnline = liveInfo.isDeviceOnline;

        // Determine Status Color & Text
        String statusText;
        Color statusColor;
        IconData statusIcon;

        if (activeMode == ConnectionMode.local ||
            connectivityState.isLocalReachable) {
          // If we can see the ESP32 locally, that's best.
          statusText = "ESP32 LOCAL";
          statusColor = Colors.cyanAccent; // Local LAN
          statusIcon = Icons.bolt_rounded;
        } else if (connectivityState.isEspHotspot) {
          // Direct Hotspot fallback
          statusText = "HOTSPOT DIRECT";
          statusColor = Colors.yellowAccent;
          statusIcon = Icons.wifi_tethering_rounded;
        } else if (!isAppConnected) {
          statusText = "NETWORK ERROR";
          statusColor = Colors.orangeAccent;
          statusIcon = Icons.wifi_off_rounded;
        } else if (!isDeviceOnline) {
          // Cloud thinks device is offline
          statusText = "ESP32 OFFLINE";
          statusColor = Colors.redAccent;
          statusIcon = Icons.cloud_off_rounded;
        } else {
          statusText = "SYSTEM ONLINE"; // Cloud is active
          statusColor = Colors.greenAccent;
          statusIcon = Icons.check_circle_rounded;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // DYNAMIC LED FLASH BACKGROUND
            _buildLedGlow(statusColor, isAppConnected, isDeviceOnline, pScale),

            Container(
              margin: EdgeInsets.only(top: (8.h * pScale).toDouble()),
              child: PixelLedBorder(
                borderRadius: (30 * pScale).toDouble(),
                strokeWidth: (1.5 * pScale).toDouble(),
                duration: const Duration(seconds: 4), // Matched with StatusCard
                colors: themeColors, // BLENDED WITH THEME
                enableInfiniteRainbow: false, // Use theme colors logic
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (16.w * pScale).toDouble(),
                    vertical: (8.h * pScale).toDouble(),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A), // Matched with _GlassButton
                    borderRadius: BorderRadius.circular(
                      (30 * pScale).toDouble(),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Sync Indicator with small LED dot
                      _buildAppSyncDot(isAppConnected, theme, pScale, fScale),
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
      },
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
