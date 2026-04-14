import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/security_log.dart';
import '../../core/system/display_engine.dart';

class SecurityHistoryView extends StatelessWidget {
  final List<SecurityLog> logs;

  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  const SecurityHistoryView({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'DATA_STREAM_EMPTY',
            style: GoogleFonts.shareTechMono(
              color: Colors.white10,
              fontSize: 12.sp,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final log = logs[index];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
        final time = _timeFormat.format(dateTime);

        return RepaintBoundary(
          child: Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF070707),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                Text(
                  "[$time]",
                  style: GoogleFonts.shareTechMono(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "BREACH_DETECTION: ${log.sensor.toUpperCase()}",
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: logs.length),
    );
  }
}
