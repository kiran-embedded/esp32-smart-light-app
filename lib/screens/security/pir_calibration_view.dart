import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/security_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/system/display_engine.dart';
import '../../widgets/security/calibration_panel.dart';

class PIRCalibrationView extends ConsumerStatefulWidget {
  const PIRCalibrationView({super.key});

  @override
  ConsumerState<PIRCalibrationView> createState() => _PIRCalibrationViewState();
}

class _PIRCalibrationViewState extends ConsumerState<PIRCalibrationView> {
  int _selectedPir = 0;

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityProvider);
    final sensorKeys = securityState.sensors.keys.toList();

    if (_selectedPir >= sensorKeys.length && sensorKeys.isNotEmpty) {
      _selectedPir = 0;
    }

    final pirKey = sensorKeys.isNotEmpty ? sensorKeys[_selectedPir] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),

                // 2. Real-time Pulse Diagnostic Hub
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildDiagnosticVisualizer(securityState, pirKey),
                  ),
                ),

                // 3. Industrial Configuration Hub
                Expanded(
                  flex: 5,
                  child: _buildConfigHub(securityState, pirKey),
                ),
              ],
            ),
          ),

          // Technical Back Arrow
          Positioned(
            top: 10.h,
            left: 10.w,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.terminal_rounded,
                  color: Colors.white30,
                  size: 20.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Text(
            "NEURAL_DIAGNOSTIC_CONSOLE",
            style: GoogleFonts.shareTechMono(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "HARDWARE_ABSTRACTION_LAYER_v2.0",
            style: GoogleFonts.shareTechMono(
              fontSize: 8.sp,
              color: Colors.cyanAccent.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildDiagnosticVisualizer(SecurityState state, String? pirKey) {
    final pulses = state.satPulseData[pirKey ?? ""] ?? 0;
    final requiredPulses = state.satConfig.pulses;
    final percentage = (pulses / requiredPulses).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circual Diagnostic Meter
            SizedBox(
              width: 200.w,
              height: 200.h,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 2.h,
                backgroundColor: Colors.white.withOpacity(0.02),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pulses >= requiredPulses
                      ? Colors.redAccent
                      : Colors.cyanAccent,
                ),
              ),
            ),

            // Raw Pulse Count
            Column(
              children: [
                Text(
                  "0$pulses",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 64.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "PULSES_DETECTED",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 8.sp,
                    color: Colors.white24,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // Digital Step Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(requiredPulses, (index) {
            final active = index < pulses;
            return Container(
              width: 20.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: active
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConfigHub(SecurityState state, String? pirKey) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF070707),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTechnicalTabs(state),
            SizedBox(height: 32.h),
            const CalibrationPanel(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalTabs(SecurityState state) {
    final sensorKeys = state.sensors.keys.toList();
    if (sensorKeys.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(sensorKeys.length, (index) {
          final isSelected = _selectedPir == index;
          final key = sensorKeys[index];
          final name = state.sensors[key]?.nickname ?? key;

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() => _selectedPir = index);
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white10,
                ),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                name.toUpperCase(),
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: isSelected ? Colors.black : Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// End of PIRCalibrationView
