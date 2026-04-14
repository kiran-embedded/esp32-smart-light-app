import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';

class CalibrationHubOverlay extends ConsumerStatefulWidget {
  const CalibrationHubOverlay({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Calibration",
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const CalibrationHubOverlay(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15 * anim1.value,
            sigmaY: 15 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CalibrationHubOverlay> createState() =>
      _CalibrationHubOverlayState();
}

class _CalibrationHubOverlayState extends ConsumerState<CalibrationHubOverlay> {
  String _currentTip =
      "SYSTEM_READY: Select a diagnostic parameter to view detailed technical documentation.";
  String _tipContext = "IDLE_MONITOR";
  String _deepExplainer =
      "The Calibration Hub allows for precision tuning of the Satellite's CPU-level motion detection algorithm. These settings directly impact power consumption and trigger accuracy.";

  void _updateTip(String key) {
    setState(() {
      _tipContext = key.toUpperCase();
      switch (key) {
        case "pulses":
          _currentTip = "PULSE_VERIFICATION (P_VER)";
          _deepExplainer =
              "Defines the number of high-logic pulses required within the window to confirm human presence. \n\n• Level 1: Extreme sensitivity (may ghost)\n• Level 2: Residential Standard\n• Level 3+: Industrial Traffic Filtering.";
          break;
        case "window":
          _currentTip = "TEMPORAL_WINDOW (T_WND)";
          _deepExplainer =
              "The duration (in seconds) the CPU tracks hits before resetting the pulse counter. Larger windows are needed for slow-moving targets in cold environments.";
          break;
        case "gap":
          _currentTip = "ELECTRONIC_GAP (E_GAP)";
          _deepExplainer =
              "The 'Cool-down' period after a successful detection. Prevents redundant Firebase updates and saves WiFi bandwidth by limiting frequency.";
          break;
        case "valid":
          _currentTip = "PULSE_VALIDITY (P_VAL)";
          _deepExplainer =
              "Filters out electromagnetic interference (EMI). Any signal shorter than this threshold (in ms) is ignored by the hardware as 'noise'.";
          break;
        case "hold":
          _currentTip = "MOTION_HOLD (M_HLD)";
          _deepExplainer =
              "The duration the Relay output and UI status remain 'ACTIVE' after motion ceases. Essential for automation lighting persistence.";
          break;
        default:
          _currentTip = "SYSTEM_READY";
          _deepExplainer = "Select a parameter to view documentation.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final config = securityState.satConfig;
    final pulseData = securityState.satPulseData;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 32.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildAdvancedAssistant(),
                      SizedBox(height: 24.h),
                      _buildParamGrid(config, pulseData),
                      SizedBox(height: 32.h),
                      _buildResetSection(),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DIAGNOSTIC",
              style: GoogleFonts.outfit(
                color: Colors.cyanAccent,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            Text(
              "CALIBRATION HUB",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticService.medium();
            Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.all(12.p),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(Icons.close_rounded, color: Colors.white, size: 24.sp),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildAdvancedAssistant() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.p),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.p),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.cyanAccent,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Animate(
                key: ValueKey(_tipContext),
                effects: [
                  FadeEffect(),
                  SlideEffect(begin: const Offset(0.2, 0)),
                ],
                child: Text(
                  "ADVANCED_HELPER // $_tipContext",
                  style: GoogleFonts.outfit(
                    color: Colors.cyanAccent,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Animate(
            key: ValueKey(_currentTip),
            effects: [FadeEffect()],
            child: Text(
              _currentTip,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Animate(
            key: ValueKey(_deepExplainer),
            effects: [FadeEffect()],
            child: Text(
              _deepExplainer,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamGrid(SatelliteConfig config, Map<String, int> pulseData) {
    return Column(
      children: [
        _buildSlider(
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
        _buildSlider(
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
        _buildSlider(
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
        _buildSlider(
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
        _buildSlider(
          label: "MOTION_HOLD_TIME",
          value: config.hold / 1000.0,
          min: 1,
          max: 60,
          divisions: 59,
          suffix: " SEC",
          configKey: "hold",
          multiplier: 1000,
          icon: Icons.speed_rounded,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildSlider({
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
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.p),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withOpacity(0.7), size: 16.sp),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$suffix",
                style: GoogleFonts.shareTechMono(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (configKey == "pulses")
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                children: List.generate(value.toInt(), (index) {
                  final bool isTriggered = index < currentPulse;
                  return Expanded(
                    child: Container(
                      height: 4.h,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: isTriggered ? color : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: isTriggered
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  );
                }),
              ),
            ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withOpacity(0.05),
              thumbColor: Colors.white,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 2.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
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
              onChangeEnd: (_) => HapticService.medium(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetSection() {
    return Container(
      padding: EdgeInsets.all(20.p),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.redAccent, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FACTORY RESET",
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "Restore all diagnostic parameters to their pre-coded industrial baselines.",
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () => _showResetConfirmation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                ),
              ),
              child: Text(
                "PERFORM FACTORY ALIGNMENT",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    HapticService.heavy();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
          ),
          title: Text(
            "RESET DIAGNOSTICS?",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "This will overwrite all current sensor calibrations with baseline values. Hardware response may change.",
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: GoogleFonts.outfit(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(securityProvider.notifier).resetSatConfigToDefaults();
                Navigator.pop(context);
                HapticService.selection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text(
                "RESET",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
