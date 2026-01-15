import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TimeDateWidget extends StatelessWidget {
  const TimeDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM dd');

    final hour = now.hour;
    String greeting = "GOOD MORNING";
    if (hour >= 12 && hour < 17)
      greeting = "GOOD AFTERNOON";
    else if (hour >= 17 && hour < 21)
      greeting = "GOOD EVENING";
    else if (hour >= 21 || hour < 5)
      greeting = "GOOD NIGHT";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting Text
        Text(
          greeting,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5, end: 0),

        const SizedBox(height: 10),

        // Advanced Clock
        StreamBuilder(
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
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.orbitron(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ampm,
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),

        // Date & Advanced Weather Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAdvancedWeatherIcon(theme),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(now).toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedWeatherIcon(ThemeData theme) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color:
            (isNight ? theme.colorScheme.tertiary : theme.colorScheme.primary)
                .withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                (isNight
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary)
                    .withOpacity(0.4),
            blurRadius: 15,
          ),
        ],
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
    );
  }
}
