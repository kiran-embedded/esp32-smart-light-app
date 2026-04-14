import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/ui/responsive_layout.dart';

class TimeDateWidget extends ConsumerWidget {
  final bool compact;
  const TimeDateWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM dd');

    final authService = ref.watch(authServiceProvider);
    final userName =
        authService.currentUser?.displayName?.split(' ').first ?? "USER";

    // Dynamic phrase
    final welcomePhrase = "WELCOME BACK, $userName";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!compact) ...[
          Text(
            welcomePhrase,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ).animate().fadeIn(duration: 80.ms).slideY(begin: -0.5, end: 0),
          const SizedBox(height: 4),
        ],

        // Advanced Clock
        RepaintBoundary(
          child: StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final currentTime = DateTime.now();
              final timeStr = DateFormat('hh:mm').format(currentTime);
              final ampm = DateFormat('a').format(currentTime);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        theme.colorScheme.primary.withOpacity(0.8),
                        theme.colorScheme.primary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: compact ? 34.sp : 64.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ampm,
                    style: GoogleFonts.outfit(
                      fontSize: compact ? 11.sp : 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 4),
        // Date & Advanced Weather Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!compact) _buildAdvancedWeatherIcon(theme),
            if (!compact) const SizedBox(width: 12),
            Text(
              dateFormat.format(now).toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: compact ? 9.sp : 11.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms, duration: 80.ms),
      ],
    );
  }

  Widget _buildAdvancedWeatherIcon(ThemeData theme) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;

    return RepaintBoundary(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              (isNight ? theme.colorScheme.tertiary : theme.colorScheme.primary)
                  .withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: const [],
        ),
        child:
            Icon(
                  isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: isNight
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                  size: 18,
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 2.seconds,
                ),
      ),
    );
  }
}
