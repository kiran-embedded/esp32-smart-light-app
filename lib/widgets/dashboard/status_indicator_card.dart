import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/ui/responsive_layout.dart';

class StatusIndicatorRow extends StatelessWidget {
  final bool isESPConnected;

  const StatusIndicatorRow({
    super.key,
    required this.isESPConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final dotColor = isESPConnected ? activeColor : Colors.redAccent;

    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF090F0C).withOpacity(0.65),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color(0x3D00FF66),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            child: Icon(
              Icons.memory_rounded,
              color: isESPConnected ? activeColor : Colors.white.withOpacity(0.4),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ESP32 CORE HUB',
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isESPConnected ? 'CONNECTED' : 'OFFLINE',
                  style: GoogleFonts.outfit(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: isESPConnected ? activeColor.withOpacity(0.9) : Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          // Pulsing status dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                begin: 0.3,
                end: 1.0,
                duration: 1200.ms,
              ),
        ],
      ),
    );
  }
}
