import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../providers/update_provider.dart';

class SprinklingWatermark extends ConsumerWidget {
  const SprinklingWatermark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final versionAsync = ref.watch(currentVersionProvider);
    final accentColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sprinkle Particles
          ...List.generate(12, (index) {
            final random = math.Random(index);
            final x = (random.nextDouble() - 0.5) * 240;
            final y = (random.nextDouble() - 0.5) * 60;
            final size = 1.0 + random.nextDouble() * 2.5;

            return Positioned(
              child:
                  Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.4),
                          boxShadow: const [],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(
                        delay: (random.nextDouble() * 2000).ms,
                        duration: 80.ms,
                      )
                      .move(
                        begin: const Offset(0, 0),
                        end: Offset(0, -10 - (random.nextDouble() * 15)),
                        duration: (2000 + random.nextDouble() * 1000).ms,
                      )
                      .fadeOut(duration: 80.ms),
              left: (MediaQuery.of(context).size.width / 2) + x,
              top: 30 + y,
            );
          }),

          // Text Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              versionAsync
                  .when(
                    data: (version) => Text(
                      "Version $version",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5), // Brighter
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => Text(
                      "Version 1.2.0+34.5",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  )
                  .animate()
                  .shimmer(
                    duration: 3.seconds,
                    color: accentColor.withOpacity(0.3),
                  ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0),
                          accentColor.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                        "2026 KIRAN EMBEDDED GITHUB",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.4), // Brighter
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2500.ms, color: Colors.white24)
                      .custom(
                        duration: 2.seconds,
                        builder: (context, value, child) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            boxShadow: const [],
                          ),
                          child: child,
                        ),
                      ),
                  const SizedBox(width: 15),
                  Container(
                    width: 20,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.4),
                          accentColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}
