import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class AnimatedNavIcon extends ConsumerWidget {
  final IconData icon;
  final bool isSelected;
  final String label;

  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    // Base color logic
    final baseColor = isSelected
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.3);

    // Create the base icon widget
    Widget iconWidget = Icon(
      icon,
      size: 26, // Slightly larger for better visibility
      color: baseColor,
      shadows: isSelected
          ? [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ]
          : [],
    );

    // If not selected, return static icon (maybe with tiny hover effect if needed, but keeping simple for now)
    if (!isSelected) {
      return iconWidget;
    }

    // --- DISTINCT ANIMATIONS PER THEME ---
    // The user wants "wow" factors and distinct differences.

    switch (themeMode) {
      // 1. NEON TOKYO: Cyberpunk Glitch & Shake
      // Fast, erratic, colorful.
      case AppThemeMode.neonTokyo:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .custom(
              duration: 300.ms,
              builder: (context, value, child) {
                // Glitch effect: slight random offsets could be simulated,
                // but here we use shake + color tinting loop
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                      theme.colorScheme.primary,
                    ],
                    transform: GradientRotation(value * 6.28),
                  ).createShader(bounds),
                  child: child,
                );
              },
            )
            .shake(
              hz: 4,
              offset: const Offset(2, 2),
              duration: 1200.ms,
            ) // Jitter
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 200.ms,
            );

      // 2. CRIMSON VAMPIRE: Organic Heartbeat
      // Slow, deep pulse.
      case AppThemeMode.crimsonVampire:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.25, 1.25),
              curve: Curves.easeInOutSine, // Smooth organic pulse
              duration: 800.ms,
            )
            .tint(
              color: const Color(0xFFFF0000),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ); // Pulse redder

      // 3. APPLE GLASS: Premium Bounce & Slide
      // Clean, physics-based spring.
      case AppThemeMode.appleGlass:
        return iconWidget
            .animate()
            .moveY(
              begin: 10,
              end: 0,
              curve: Curves.easeOutBack, // Overshoot enter
              duration: 600.ms,
            )
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut, // Bouncy pop
              duration: 800.ms,
            )
            .shimmer(
              duration: 1200.ms,
              color: Colors.white.withValues(alpha: 0.8),
              angle: 0.5,
            );

      // 4. KALI LINUX: Terminal Cursor / Blink
      // Digital, on/off, raw.
      case AppThemeMode.kaliLinux:
        return iconWidget
            .animate(onPlay: (c) => c.repeat())
            .toggle(
              builder: (_, value, child) => Opacity(
                opacity: value ? 1.0 : 0.0, // Hard blink like a cursor
                child: child,
              ),
              duration: 500.ms, // 1s cycle
            )
            .scale(end: const Offset(1.1, 1.1), duration: 0.ms); // Static scale

      // 5. NOTHING DOT: Retro Flip / Pixel
      // Mechanical feel.
      case AppThemeMode.nothingDot:
        return iconWidget
            .animate()
            .flip(
              direction: Axis.horizontal,
              duration: 400.ms,
              curve: Curves.easeInOutBack,
            ) // Spin into view
            .then() // After spin
            .shakeX(
              hz: 8,
              amount: 2,
              duration: 300.ms,
            ); // Mechanical lock jiggle

      // 6. LIQUID GLASS: Jelly / Morph
      // Flexible, rubbery.
      case AppThemeMode.liquidGlass:
        return iconWidget
            .animate()
            .scaleXY(
              begin: 0.5,
              end: 1.2,
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .then()
            .scaleXY(
              begin: 1.2,
              end: 1.0,
              duration: 600.ms,
              curve: Curves.elasticOut,
            ); // Wobble settle

      // 7. RAINDROP: Drop & Splash
      // Falling down.
      case AppThemeMode.raindrop:
        return iconWidget
            .animate()
            .moveY(
              begin: -20,
              end: 0,
              duration: 600.ms,
              curve: Curves.bounceOut,
            ) // Fall and bounce
            .fadeIn(duration: 200.ms);

      // 8. DARK SPACE: Zero-G Float
      // Slow, eerie, rotating.
      case AppThemeMode.darkSpace:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -3,
              end: 3,
              duration: 2000.ms,
              curve: Curves.easeInOutSine,
            ) // Slow float
            .rotate(
              begin: -0.05,
              end: 0.05,
              duration: 3000.ms,
              curve: Curves.easeInOutSine,
            ); // Gentle slow rotation

      // 9. CYBER NEON / AMOLED CYBERPUNK: High Energy Pulse
      // Intense glow interaction.
      case AppThemeMode.cyberNeon:
      case AppThemeMode.amoledCyberpunk:
        return iconWidget
            .animate(onPlay: (c) => c.repeat())
            .elevation(
              end: 10,
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(100),
            )
            .shake(hz: 2, rotation: 0.1, duration: 1000.ms) // Vibration
            .saturate(begin: 1.0, end: 2.0, duration: 1000.ms);

      // 11. SUNSET RETRO: Vaporwave Glide
      // 11. SUNSET RETRO: Vaporwave Rotator
      case AppThemeMode.sunsetRetro:
        return iconWidget
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 4000.ms) // Slow infinite rotation
            .shimmer(
              duration: 2000.ms,
              color: const Color(0xFFFF9E80),
            ) // Orange shimmer
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
              curve: Curves.easeInOut,
            );

      // 12. MINDFUL NATURE: Organic Bloom
      case AppThemeMode.mindfulNature:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.3, 1.3), // Larger bloom
              curve: Curves.easeInOutQuad,
              duration: 2500.ms,
            )
            .rotate(
              begin: -0.05,
              end: 0.05,
              duration: 3000.ms,
              curve: Curves.easeInOutSine,
            ); // Gentle leaf sway

      // 13. DEEP OCEAN: Sonar Pulse & Float
      case AppThemeMode.deepOcean:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -8,
              curve: Curves.easeInOutSine,
              duration: 3000.ms,
            )
            .custom(
              duration: 2000.ms,
              builder: (context, value, child) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00BFA5,
                      ).withValues(alpha: (1 - value) * 0.5),
                      blurRadius: value * 20,
                      spreadRadius: value * 10,
                    ),
                  ],
                ),
                child: child,
              ),
            );

      // 14. DRACULA: Bat Flicker & Shake
      case AppThemeMode.dracula:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shake(
              hz: 8,
              offset: const Offset(1, 0),
              duration: 2000.ms,
            ) // Nervous shake
            .tint(color: const Color(0xFFFF79C6), duration: 1000.ms)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: 400.ms,
              curve: Curves.elasticOut,
            );

      // 15. MONOKAI: Code Spin & Overshoot
      case AppThemeMode.monokai:
        return iconWidget
            .animate(onPlay: (c) => c.repeat())
            .rotate(
              duration: 2000.ms,
              curve: Curves.easeInOutBack,
            ) // Continuous spin
            .scaleXY(
              begin: 0.8,
              end: 1.2,
              duration: 1000.ms,
              curve: Curves.easeInOut,
            )
            .then(delay: 500.ms)
            .scaleXY(begin: 1.2, end: 0.8);

      // 16. SYNTHWAVE: Hyper Glitch (Neon Tokyo Style)
      case AppThemeMode.synthwave:
        return iconWidget
            .animate(onPlay: (c) => c.repeat())
            .shake(
              hz: 10,
              offset: const Offset(3, 3),
              rotation: 0.1,
              duration: 800.ms,
            ) // Heavy Glitch
            .saturate(begin: 1.0, end: 3.0, duration: 500.ms)
            .tint(color: Colors.white, duration: 100.ms) // Flash
            .then(delay: 200.ms)
            .tint(color: const Color(0xFFEB00FF), duration: 500.ms);

      // 10. LIGHT / SOFT DARK / DARK NEON: Professional Elevation
      // Subtle rise.
      case AppThemeMode.light:
      case AppThemeMode.softDark:
      case AppThemeMode.darkNeon:

        // Elegant rise and refined glow
        return iconWidget
            .animate()
            .moveY(
              begin: 5,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutQuad,
            )
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.1, 1.1),
              duration: 300.ms,
            )
            .custom(
              duration: 500.ms,
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -2 * value),
                  child: child,
                );
              },
            );

      case AppThemeMode.solarFlare:
      case AppThemeMode.magmaCore:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: 1000.ms,
            )
            .tint(color: Colors.orange, duration: 1000.ms);

      case AppThemeMode.electricTundra:
      case AppThemeMode.voidRift:
      case AppThemeMode.starlightEcho:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 2500.ms)
            .shimmer(
              duration: 2000.ms,
              color: Colors.blueAccent.withValues(alpha: 0.3),
            );

      case AppThemeMode.nanoCatalyst:
      case AppThemeMode.cyberBloom:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .blur(
              begin: const Offset(0, 0),
              end: const Offset(2, 2),
              duration: 1500.ms,
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 1500.ms,
            );

      case AppThemeMode.phantomVelvet:
      case AppThemeMode.prismFractal:
      case AppThemeMode.aeroStream:
        return iconWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms)
            .moveX(begin: -2, end: 2, duration: 3000.ms);
    }
  }
}
