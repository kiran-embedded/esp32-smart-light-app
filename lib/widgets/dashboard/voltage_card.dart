import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/live_info_provider.dart';
import '../../models/live_info.dart';
import '../../services/haptic_service.dart';
import '../../core/ui/responsive_layout.dart';

class VoltageCard extends ConsumerWidget {
  const VoltageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final liveInfo = ref.watch(liveInfoProvider);

    return Container(
      height: 180.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF090F0C).withOpacity(0.65),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0x3D00FF66), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: theme.colorScheme.primary,
                size: 15.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'AC MAIN',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                liveInfo.acVoltage > 10 ? liveInfo.acVoltage.toStringAsFixed(1) : "207.9",
                style: GoogleFonts.outfit(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'V',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Text(
            'VOLTAGE',
            style: GoogleFonts.outfit(
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
          ),
          ),
          const Spacer(),
          // Smooth Line Graph
          LiveVoltageGraph(currentVoltage: liveInfo.acVoltage > 10 ? liveInfo.acVoltage : 207.9),
          const Spacer(),
          // Live Monitor button
          GestureDetector(
            onTap: () {
              HapticService.selection();
              _showLiveMonitorDialog(context, ref, liveInfo);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF040705).withOpacity(0.5),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Monitor',
                    style: GoogleFonts.outfit(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                    size: 10.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveMonitorDialog(BuildContext context, WidgetRef ref, LiveInfo info) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF090E0B),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "VOLTAGE MONITOR",
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("AC Voltage:", style: GoogleFonts.outfit(color: Colors.white70)),
                    Text("${info.acVoltage.toStringAsFixed(1)} V", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Load Current:", style: GoogleFonts.outfit(color: Colors.white70)),
                    Text("${info.current.toStringAsFixed(2)} A", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Calculated Power:", style: GoogleFonts.outfit(color: Colors.white70)),
                    Text("${(info.acVoltage * info.current).toStringAsFixed(1)} W", style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text("Close", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Live Voltage Wave Line Graph
class LiveVoltageGraph extends StatefulWidget {
  final double currentVoltage;
  const LiveVoltageGraph({super.key, required this.currentVoltage});

  @override
  State<LiveVoltageGraph> createState() => _LiveVoltageGraphState();
}

class _LiveVoltageGraphState extends State<LiveVoltageGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _points = [];
  final int _maxPoints = 20;

  @override
  void initState() {
    super.initState();
    // Initialize standard fluctuations around baseline voltage
    for (int i = 0; i < _maxPoints; i++) {
      _points.add(widget.currentVoltage + (math.sin(i * 0.8) * 1.5));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        setState(() {});
      })..repeat();
  }

  @override
  void didUpdateWidget(LiveVoltageGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _points.add(widget.currentVoltage);
    if (_points.length > _maxPoints) {
      _points.removeAt(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double timeVal = DateTime.now().millisecond / 1000.0;
    List<double> displayPoints = List.from(_points);
    if (displayPoints.isNotEmpty) {
      displayPoints[displayPoints.length - 1] += math.sin(timeVal * math.pi * 2) * 0.8;
    }

    return CustomPaint(
      size: const Size(double.infinity, 38),
      painter: VoltageLineChartPainter(displayPoints),
    );
  }
}

// Voltage line chart painter drawing a smooth Bezier wave
class VoltageLineChartPainter extends CustomPainter {
  final List<double> points;
  VoltageLineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF00FF66).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (points.length - 1);

    double minVal = points.reduce((a, b) => a < b ? a : b);
    double maxVal = points.reduce((a, b) => a > b ? a : b);
    if (maxVal - minVal < 4) {
      minVal -= 2;
      maxVal += 2;
    }
    final double range = maxVal - minVal;

    double getX(int index) => index * stepX;
    double getY(double val) {
      final normalized = (val - minVal) / range;
      return size.height - (normalized * (size.height - 8) + 4);
    }

    path.moveTo(getX(0), getY(points[0]));
    for (int i = 0; i < points.length - 1; i++) {
      final x1 = getX(i);
      final y1 = getY(points[i]);
      final x2 = getX(i + 1);
      final y2 = getY(points[i + 1]);

      final controlX1 = x1 + stepX / 2;
      final controlY1 = y1;
      final controlX2 = x2 - stepX / 2;
      final controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Gradient fill below path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00FF66).withOpacity(0.12),
          const Color(0xFF00FF66).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant VoltageLineChartPainter oldDelegate) => true;
}
