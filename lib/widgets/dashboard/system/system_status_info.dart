import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemStatusInfo extends StatelessWidget {
  final bool isOnline;

  const SystemStatusInfo({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final systemStatusTitle = isOnline ? 'SYSTEM ACTIVE' : 'SYSTEM OFFLINE';
    final systemStatusSub = isOnline ? 'All systems operating' : 'Monitoring power state';
    final statusColor = isOnline ? primary : Colors.redAccent;

    return Row(
      children: [
        Container(
          width: 1,
          height: 40,
          color: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STATUS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                Text(
                  systemStatusTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              systemStatusSub,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        const Spacer(),
        const Icon(Icons.chevron_right, color: Colors.white54),
      ],
    );
  }
}
