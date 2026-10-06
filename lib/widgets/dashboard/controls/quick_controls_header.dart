import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickControlsHeader extends StatelessWidget {
  const QuickControlsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, color: primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'QUICK CONTROLS',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Icon(Icons.more_horiz, color: Colors.white54),
      ],
    );
  }
}
