import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/security_provider.dart';
import '../../services/performance_monitor_service.dart';
import '../../services/haptic_service.dart';

class DeveloperTestOverlay extends ConsumerStatefulWidget {
  const DeveloperTestOverlay({super.key});

  @override
  ConsumerState<DeveloperTestOverlay> createState() =>
      _DeveloperTestOverlayState();
}

class _DeveloperTestOverlayState extends ConsumerState<DeveloperTestOverlay> {
  @override
  void initState() {
    super.initState();
    debugPrint("OVERLAY_LOG: InitState");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(performanceStatsProvider.notifier).startMonitoring();
    });
  }

  void _close() {
    debugPrint("OVERLAY_LOG: Closing via UI");
    HapticService.medium();
    ref.read(performanceStatsProvider.notifier).toggleConsole(false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(performanceStatsProvider);
    final securityState = ref.watch(securityProvider);
    debugPrint("OVERLAY_LOG: Starting build. Visible: ${stats.consoleVisible}");
    debugPrint("OVERLAY_LOG: State Watched. HubMAC: ${securityState.hubMac}");

    return Positioned.fill(
      child: Stack(
        children: [
          // Background Dim
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
          ),

          // Ultra-Minimal Box
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border.all(
                  color: Colors.cyanAccent,
                  width: 2,
                ), // Refined cyan border
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "NEBULA DEV CONSOLE",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),
                  _row("FPS:", stats.fps.toStringAsFixed(1), Colors.green),
                  _row(
                    "CPU:",
                    "${(stats.cpuUsage * 100).toInt()}%",
                    Colors.orange,
                  ),
                  _row("MEM:", "${stats.memoryUsage.toInt()}MB", Colors.purple),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  _smallRow("HUB MAC:", securityState.hubMac),
                  _smallRow("SAT MAC:", securityState.satMac),
                  _smallRow(
                    "ESP-NOW:",
                    securityState.satLastSeen < 30 ? "SYNCED" : "LOST",
                    securityState.satLastSeen < 30
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  _smallRow("LAST BEAT:", "${securityState.satLastSeen}s ago"),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "GLOBAL FPS METER",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Switch(
                        value: stats.globalFpsEnabled,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) {
                          HapticService.selection();
                          ref
                              .read(performanceStatsProvider.notifier)
                              .toggleGlobalFps(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "DIAGNOSTIC ACTIVE",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              color: c,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallRow(String l, String v, [Color c = Colors.white38]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: GoogleFonts.outfit(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            v,
            style: GoogleFonts.outfit(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
