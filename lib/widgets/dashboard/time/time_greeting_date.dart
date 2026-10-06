import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeGreetingDate extends StatelessWidget {
  final DateTime time;
  const TimeGreetingDate({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];

    final weekday = weekdays[time.weekday - 1];
    final month = months[time.month - 1];
    final dateStr = '$weekday, $month ${time.day}';

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, color: primary, size: 20),
        const SizedBox(width: 12),
        Text(
          dateStr,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
