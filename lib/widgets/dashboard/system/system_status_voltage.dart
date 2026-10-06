import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemStatusVoltage extends StatelessWidget {
  final double voltage;
  final bool isOnline;

  const SystemStatusVoltage({
    super.key,
    required this.voltage,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final voltageStatusColor = isOnline ? primary : Colors.redAccent;
    final voltageStatus = isOnline ? 'Voltage Normal' : 'Low/Offline';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Center(
            child: Icon(
              Icons.bolt,
              color: primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AC MAIN',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  voltage.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Text(
                  ' V',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              voltageStatus,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
