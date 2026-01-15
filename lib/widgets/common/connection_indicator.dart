import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/connection_settings_provider.dart';

class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(connectionSettingsProvider);

    String label = 'CLOUD';
    Color color = const Color(0xFF00C2FF); // Sky Blue
    IconData icon = Icons.cloud_queue_rounded;

    if (settings.mode == ConnectionMode.local) {
      label = 'LOCAL';
      color = const Color(0xFF00FFC2); // Aqua
      icon = Icons.wifi_tethering_rounded;
    } else if (settings.mode == ConnectionMode.hybrid) {
      label = 'HYBRID';
      color = Colors.purpleAccent;
      icon = Icons.flash_on_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2.seconds,
                color: Colors.white.withOpacity(0.5),
              ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          // Pulsing Dot
          Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                duration: 1.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: 1.seconds,
                begin: const Offset(1.5, 1.5),
                end: const Offset(1, 1),
                curve: Curves.easeInOut,
              )
              .fadeOut(duration: 1.seconds),
        ],
      ),
    );
  }
}
