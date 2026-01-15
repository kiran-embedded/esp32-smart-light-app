import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                  const SizedBox(height: 20),
                  _row("FPS:", stats.fps.toStringAsFixed(1), Colors.green),
                  _row(
                    "CPU:",
                    "${(stats.cpuUsage * 100).toInt()}%",
                    Colors.orange,
                  ),
                  _row("MEM:", "${stats.memoryUsage.toInt()}MB", Colors.purple),
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
