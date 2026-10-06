import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/ui/responsive_layout.dart';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF090F0C).withOpacity(0.65),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0x3D00FF66), width: 0.8),
        ),
        child: Row(
          children: [
            // Circular icon wrapper
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 16.sp,
              ),
            ),
            SizedBox(width: 10.w),
            // Text details (Middle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 9.sp,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron arrow (Far right)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.primary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
