import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeGreetingClock extends StatelessWidget {
  final DateTime time;
  const TimeGreetingClock({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          hourStr,
          style: GoogleFonts.outfit(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: primary,
            height: 1.0,
          ),
        ),
        Text(
          ':$minStr',
          style: GoogleFonts.outfit(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amPm,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ],
    );
  }
}
