import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/performance_monitor_service.dart';
import '../../core/ui/responsive_layout.dart';

class GlobalFpsMeter extends ConsumerWidget {
  const GlobalFpsMeter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(performanceStatsProvider);

    if (!stats.globalFpsEnabled) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10.h,
      right: 20.w,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: stats.fps < 55
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.cyanAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: BoxDecoration(
                    color: stats.fps < 55
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (stats.fps < 55
                                    ? Colors.redAccent
                                    : Colors.greenAccent)
                                .withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  "${stats.fps.toInt()} FPS",
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5.w,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
