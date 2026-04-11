import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/neural_logic_provider.dart';
import '../../services/haptic_service.dart';

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
    final liveInfo = ref.watch(liveInfoProvider);
    final theme = Theme.of(context);
    final sensorKeys = securityState.sensors.keys.toList();

    // Ensure _selectedPir is within bounds if sensors were deleted
    if (_selectedPir >= sensorKeys.length && sensorKeys.isNotEmpty) {
      _selectedPir = 0;
    }

    final pirKey = sensorKeys.isNotEmpty ? sensorKeys[_selectedPir] : null;
    final signal = pirKey != null ? liveInfo.signals[_selectedPir] : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Ambient Glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),

                // 2. Neural Spectrum Visualizer
                Expanded(
                  flex: 3,
                  child: Center(child: _buildSpectrumVisualizer(signal, theme)),
                ),

                // 3. Calibration Controls
                Expanded(
                  flex: 4,
                  child: _buildControls(theme, securityState, pirKey),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 🤖 CALIBRATION HELPER BOT
          Positioned(
            bottom: 30,
            right: 20,
            child: SafeArea(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showCalibrationGuide(context),
                  child:
                      Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.cyanAccent,
                              size: 26,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(duration: 2000.ms, color: Colors.white24)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalibrationGuide(BuildContext context) {
    HapticService.heavy();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Colors.cyanAccent,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  "NEURAL GUIDE",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildGuideItem(
              "⚡ FAST MODE",
              "Triggers on a single hit. Use for instant light activation in low-noise areas.",
              Colors.cyanAccent,
            ),
            _buildGuideItem(
              "⚖ BALANCED MODE",
              "Standard 2-hit logic. Filters out sudden environment flashes or minor sensor jitter.",
              Colors.orangeAccent,
            ),
            _buildGuideItem(
              "🛡 STRICT MODE",
              "Industrial 3-hit verification. Absolute maximum false-alarm protection.",
              Colors.lightGreenAccent,
            ),
            const Divider(color: Colors.white10, height: 32),
            _buildGuideItem(
              "⌛ DEBOUNCE TIMER",
              "The logic 'locking' window. Set to 800ms to ensure distinct movements are counted correctly.",
              Colors.white54,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("I UNDERSTAND"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            "NEURAL CALIBRATION",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "SENSOR ENGINE OPTIMIZATION",
            style: GoogleFonts.outfit(
              fontSize: 8,
              color: Colors.cyanAccent.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  // Legacy visualizer removed.

  Widget _buildSpectrumVisualizer(int signal, ThemeData theme) {
    final color = theme.colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 140, // Increased height for better crispness
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(16, (index) {
              // More bars for finer grain
              final active = index < (signal / 6.25);
              return AnimatedContainer(
                duration: Duration(milliseconds: 50 + (index * 15)),
                width: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                height: active ? (15.0 + (index * 7.5)).clamp(10, 120) : 6,
                decoration: BoxDecoration(
                  color: active ? color : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: color.withOpacity(0.8),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "$signal%",
          style: GoogleFonts.outfit(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
          ),
        ).animate(key: ValueKey(signal)).shimmer(duration: 400.ms),
        Text(
          "NEURAL SIGNAL INTENSITY",
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: color.withOpacity(0.6),
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    ThemeData theme,
    SecurityState securityState,
    String? pirKey,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPirSelector(),
            const SizedBox(height: 32),
            _buildModeSelector(pirKey, securityState),
            const SizedBox(height: 32),
            _buildDetectionSelector(
              "ZONE SENSITIVITY",
              "Hits required to trigger alarm/automation",
              securityState.calibrations[pirKey]?.sensitivity ?? 1,
              (v) {
                ref
                    .read(securityProvider.notifier)
                    .updateCalibration(pirKey!, sensitivity: v);
              },
            ),
            const SizedBox(height: 32),
            _buildCalibrationRow(
              "DEBOUNCE",
              "Response delay stability (ms)",
              (securityState.calibrations[pirKey]?.debounce ?? 200).toDouble(),
              0,
              2000,
              (v) {
                ref
                    .read(securityProvider.notifier)
                    .updateCalibration(pirKey!, debounce: v.toInt());
              },
            ),
            const SizedBox(height: 32),
            _buildLiveStatusDisplay(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 0.5,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildPirSelector() {
    final securityState = ref.watch(securityProvider);
    final sensorKeys = securityState.sensors.keys.toList();

    if (sensorKeys.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(sensorKeys.length, (index) {
          final pirKey = sensorKeys[index];
          final isSelected = _selectedPir == index;
          final pirName = securityState.sensors[pirKey]?.nickname ?? pirKey;

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() => _selectedPir = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Text(
                pirName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white38,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildModeSelector(String? pirKey, SecurityState state) {
    if (pirKey == null) return const SizedBox.shrink();
    final currentMode = state.calibrations[pirKey]?.mode ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SECURITY ENGINE MODE",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Define how this specific sensor behaves",
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildModePill(0, "LDR", currentMode == 0, pirKey),
            const SizedBox(width: 8),
            _buildModePill(1, "TIME", currentMode == 1, pirKey),
            const SizedBox(width: 8),
            _buildModePill(2, "HYBRID", currentMode == 2, pirKey),
          ],
        ),
      ],
    );
  }

  Widget _buildModePill(
    int mode,
    String label,
    bool isSelected,
    String pirKey,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          ref.read(securityProvider.notifier).updateSensorMode(pirKey, mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.cyanAccent.withOpacity(0.1)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.cyanAccent : Colors.white24,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionSelector(
    String title,
    String subtitle,
    int currentValue,
    Function(int) onChanged,
  ) {
    final isSelected1 = currentValue == 1;
    final isSelected2 = currentValue == 2;
    final isSelected3 = currentValue >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabelPill(1, '⚡ FAST', isSelected1, onChanged),
            _buildLabelPill(2, '⚖ BALANCED', isSelected2, onChanged),
            _buildLabelPill(3, '🛡 STRICT', isSelected3, onChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveStatusDisplay(ThemeData theme) {
    final securityState = ref.watch(securityProvider);
    final switchState = ref.watch(switchDevicesProvider);
    final neuralState = ref.watch(neuralLogicProvider);
    final sensorKeys = securityState.sensors.keys.toList();

    if (sensorKeys.isEmpty || _selectedPir >= sensorKeys.length) {
      return const SizedBox.shrink();
    }

    final pirKey = sensorKeys[_selectedPir];
    final sensor = securityState.sensors[pirKey];
    final isArmed = securityState.isArmed;
    final isPanic = securityState.isAlarmActive;

    // Get mapped relays for this PIR
    final mappedRelayIndices = neuralState.pirMap[_selectedPir] ?? [];
    final mappedSwitches = switchState.where((s) {
      final idx = int.tryParse(s.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return mappedRelayIndices.contains(idx - 1);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                "PIR MOTION",
                sensor?.status ?? false ? "DETECTED" : "SECURED",
                sensor?.status ?? false
                    ? Colors.orangeAccent
                    : Colors.greenAccent,
                pulse: sensor?.status ?? false,
              ),
              _buildStatusItem(
                "ALARM SYSTEM",
                isArmed ? (isPanic ? "ALARMING" : "ARMED") : "DISARMED",
                isArmed
                    ? (isPanic ? Colors.redAccent : Colors.cyanAccent)
                    : Colors.white24,
                pulse: isPanic,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Text(
            "MAPPED NEURAL NODES",
            style: GoogleFonts.outfit(
              fontSize: 8,
              color: Colors.white24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (mappedSwitches.isEmpty)
            Text(
              "NO RELAYS MAPPED TO THIS ZONE",
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white10,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mappedSwitches.map((device) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: device.isActive
                        ? Colors.cyanAccent.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: device.isActive
                          ? Colors.cyanAccent.withOpacity(0.3)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.power_settings_new_rounded,
                        size: 10,
                        color: device.isActive
                            ? Colors.cyanAccent
                            : Colors.white24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (device.nickname ?? device.name).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: device.isActive
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.greenAccent,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  "NEURAL SYNC STANDBY",
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.greenAccent.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    Color color, {
    bool pulse = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 8,
            color: Colors.white38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (pulse)
              Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: 600.ms,
                  )
                  .fadeOut(),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelPill(
    int val,
    String label,
    bool isSelected,
    Function(int) onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap(val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: MediaQuery.of(context).size.width / 4,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label.split(' ')[1], // e.g., FAST
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.cyanAccent : Colors.white38,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.split(' ')[0], // e.g., ⚡
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationRow(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Text(
              value.toInt().toString(),
              style: GoogleFonts.outfit(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            overlayColor: Colors.cyanAccent.withOpacity(0.1),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

// End of PIRCalibrationView
