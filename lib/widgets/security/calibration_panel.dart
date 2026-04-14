import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';

class CalibrationPanel extends ConsumerStatefulWidget {
  const CalibrationPanel({super.key});

  @override
  ConsumerState<CalibrationPanel> createState() => _CalibrationPanelState();
}

class _CalibrationPanelState extends ConsumerState<CalibrationPanel> {
  String _currentTip =
      "READY_FOR_DIAGNOSTICS: Select a parameter to begin alignment.";
  String _tipContext = "SYSTEM_IDLE";

  void _updateTip(String key) {
    setState(() {
      _tipContext = key.toUpperCase();
      switch (key) {
        case "pulses":
          _currentTip =
              "PULSE_VERIFICATION: Higher values filter out pets and small thermal noise. Use 3+ for high-traffic zones.";
          break;
        case "window":
          _currentTip =
              "TEMPORAL_WINDOW: Defines how long the CPU waits for hits. Increase for large open spaces with slow movement.";
          break;
        case "gap":
          _currentTip =
              "ELECTRONIC_GAP: Prevents 'multi-triggering' from same event. Higher gap ensures cleaner telemetry logs.";
          break;
        case "valid":
          _currentTip =
              "PULSE_VALIDITY: The minimum width of a valid sensor hit. Set below 100ms for sensitive high-end PIR sensors.";
          break;
        case "hold":
          _currentTip =
              "MOTION_HOLD: Keep relay active after detection. High values (15s+) recommended for automation lighting.";
          break;
        default:
          _currentTip =
              "READY_FOR_DIAGNOSTICS: Select a parameter to begin alignment.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final config = securityState.satConfig;
    final pulseData = securityState.satPulseData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHelperBot(),
        SizedBox(height: 24.h),
        _buildSectionHeader("SATELLITE_CORE_PARAMETERS"),
        _buildIndustrialSlider(
          context,
          ref,
          label: "PULSE_VERIFICATION",
          value: config.pulses.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          suffix: " UNITS",
          configKey: "pulses",
          icon: Icons.analytics_rounded,
          color: Colors.cyanAccent,
          currentPulse: pulseData['PIR1'] ?? 0,
        ),
        _buildIndustrialSlider(
          context,
          ref,
          label: "TEMPORAL_WINDOW",
          value: config.window / 1000.0,
          min: 5,
          max: 30,
          divisions: 25,
          suffix: " SEC",
          configKey: "window",
          multiplier: 1000,
          icon: Icons.history_toggle_off_rounded,
          color: Colors.orangeAccent,
        ),
        _buildIndustrialSlider(
          context,
          ref,
          label: "ELECTRONIC_GAP",
          value: config.gap / 1000.0,
          min: 1,
          max: 10,
          divisions: 18,
          suffix: " SEC",
          configKey: "gap",
          multiplier: 1000,
          icon: Icons.timer_outlined,
          color: Colors.purpleAccent,
        ),
        _buildIndustrialSlider(
          context,
          ref,
          label: "PULSE_VALIDITY",
          value: config.valid.toDouble(),
          min: 50,
          max: 500,
          divisions: 9,
          suffix: " MS",
          configKey: "valid",
          icon: Icons.biotech_rounded,
          color: Colors.greenAccent,
        ),
        _buildIndustrialSlider(
          context,
          ref,
          label: "MOTION_HOLD_TIME",
          value: config.hold / 1000.0,
          min: 1,
          max: 30,
          divisions: 29,
          suffix: " SEC",
          configKey: "hold",
          multiplier: 1000,
          icon: Icons.speed_rounded,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildHelperBot() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.p),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // Increased visibility
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ), // Increased contrast
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12.p),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_outlined,
              color: Colors.cyanAccent,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Animate(
                  key: ValueKey(_tipContext),
                  effects: [
                    FadeEffect(duration: 200.ms),
                    SlideEffect(begin: const Offset(-0.1, 0), duration: 200.ms),
                  ],
                  child: Text(
                    "DIAGNOSTIC_ASSISTANT // $_tipContext",
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Animate(
                  key: ValueKey(_currentTip),
                  effects: [FadeEffect(duration: 400.ms)],
                  child: Text(
                    _currentTip,
                    style: GoogleFonts.outfit(
                      color: Colors.white, // Pure white for text
                      fontSize: 11.sp,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 16.h, top: 4.h),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildIndustrialSlider(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required String configKey,
    required IconData icon,
    required Color color,
    int multiplier = 1,
    int currentPulse = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(18.p),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), // Increased
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)), // Increased
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.p),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 14.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white, // Increased
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: color.withOpacity(0.6),
                  ), // Reinforced
                ),
                child: Text(
                  "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$suffix",
                  style: GoogleFonts.shareTechMono(
                    color: color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (configKey == "pulses")
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: List.generate(value.toInt(), (index) {
                  final bool isTriggered = index < currentPulse;
                  return Expanded(
                    child: Animate(
                      target: isTriggered ? 1 : 0,
                      effects: [ShimmerEffect(color: color.withOpacity(0.3))],
                      child: Container(
                        height: 6.h, // Thicker
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isTriggered ? color : color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: Colors.white,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 3.h, // Thicker
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (val) {
                _updateTip(configKey);
                ref
                    .read(securityProvider.notifier)
                    .updateSatConfig(configKey, (val * multiplier).toInt());
              },
              onChangeStart: (_) => HapticService.light(),
              onChangeEnd: (_) => HapticService.selection(),
            ),
          ),
        ],
      ),
    );
  }
}
