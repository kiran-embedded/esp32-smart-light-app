import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/performance_monitor_service.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';

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
    debugPrint("OVERLAY_LOG: Build Method Invoked");
    final stats = ref.watch(performanceStatsProvider);

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
                  const SizedBox(height: 10),

                  // Performance Stats
                  _row("FPS:", stats.fps.toStringAsFixed(1), Colors.green),
                  _row(
                    "CPU:",
                    "${(stats.cpuUsage * 100).toInt()}%",
                    Colors.orange,
                  ),

                  const Divider(color: Colors.white10),

                  // NADE Stats
                  const Text(
                    "DISPLAY ENGINE (NADE)",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _miniRow(
                    "Scale W/H",
                    "${DisplayEngine.scaleW.toStringAsFixed(2)} / ${DisplayEngine.scaleH.toStringAsFixed(2)}",
                  ),
                  _miniRow(
                    "Scale Min",
                    DisplayEngine.scaleMin.toStringAsFixed(2),
                  ),
                  _miniRow(
                    "Aspect Ratio",
                    DisplayEngine.aspectRatio.toStringAsFixed(2),
                  ),

                  const SizedBox(height: 10),

                  // System Architecture
                  const Text(
                    "HARDWARE DIAGNOSTICS",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _miniRow("Device", DisplayEngine.deviceModel),
                  _miniRow("Arch", DisplayEngine.cpuHardware),
                  _miniRow("OS", DisplayEngine.androidVersion),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(
            v,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            v,
            style: TextStyle(
              color: c,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
