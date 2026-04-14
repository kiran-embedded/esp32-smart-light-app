import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_switch_service.dart';
import '../../services/haptic_service.dart';
import '../../core/constants/app_constants.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

final automationProvider = StreamProvider.family<Map<String, dynamic>, int>((
  ref,
  relayIndex,
) {
  return FirebaseSwitchService().listenToAutomation(
    relayIndex,
    deviceId: AppConstants.defaultDeviceId,
  );
});

class AutomationSettingsPopup extends ConsumerStatefulWidget {
  final int relayIndex;
  final String switchName;

  const AutomationSettingsPopup({
    super.key,
    required this.relayIndex,
    required this.switchName,
  });

  @override
  ConsumerState<AutomationSettingsPopup> createState() =>
      _AutomationSettingsPopupState();
}

class _AutomationSettingsPopupState
    extends ConsumerState<AutomationSettingsPopup> {
  String _selectedSensor = "kitchen";
  int _durationSeconds = 60;
  int _ldrThreshold = 50;
  bool _isActive = false;
  int _timeMode = 0; // 0: All, 1: Morning, 2: Day, 3: Midnight

  void _loadFromData(Map<String, dynamic> data) {
    if (data.isNotEmpty && mounted) {
      if (data['sensor'] != null && data['sensor'].toString().isNotEmpty) {
        _selectedSensor = data['sensor'];
      }
      _durationSeconds = data['duration'] ?? 60;
      _ldrThreshold = data['ldr'] ?? 50;
      _isActive = data['isActive'] ?? false;
      _timeMode = data['timeMode'] ?? 0;
    }
  }

  Future<void> _saveCurrentState() async {
    await FirebaseSwitchService().updateAutomation(
      widget.relayIndex,
      _selectedSensor,
      _durationSeconds,
      _ldrThreshold,
      _isActive,
      _timeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final automationAsync = ref.watch(automationProvider(widget.relayIndex));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.05),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: automationAsync.when(
              data: (data) {
                _loadFromData(data);
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildContent(),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
                ),
              ),
              error: (e, s) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "Error: $e",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motion AI',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.switchName,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isActive,
              activeColor: Colors.cyanAccent,
              onChanged: (val) {
                HapticService.toggle(val);
                setState(() => _isActive = val);
                _saveCurrentState();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // SENSOR
        Text(
          'Trigger Sensor',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSensor,
              isExpanded: true,
              dropdownColor: const Color(0xFF222222),
              icon: const Icon(Icons.radar, color: Colors.cyanAccent),
              style: GoogleFonts.outfit(color: Colors.white),
              items: ['kitchen', 'living', 'hallway', 'garage', 'door'].map((
                s,
              ) {
                return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  HapticService.impactClick();
                  setState(() => _selectedSensor = val);
                  _saveCurrentState();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // TIME
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Auto-Off Timer',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            Text(
              '${_durationSeconds}s',
              style: GoogleFonts.outfit(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _durationSeconds.toDouble(),
          min: 10,
          max: 300,
          divisions: 29,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.white24,
          onChanged: (val) {
            setState(() => _durationSeconds = val.toInt());
            HapticService.immersiveSliderFeedback(val, min: 10, max: 300);
          },
          onChangeEnd: (val) {
            HapticService.selection();
            _saveCurrentState();
          },
        ),

        // QUICK DAYTIME TOGGLE
        _buildQuickDaytimeToggle(),
        const SizedBox(height: 24),

        // TIME OF DAY PRESETS
        Text(
          'Detailed Environment Preset',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        _buildIndustrialModeSelector(),
        const SizedBox(height: 24),

        // LDR
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Darkness Threshold',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            Text(
              '${_ldrThreshold}',
              style: GoogleFonts.outfit(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _ldrThreshold.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.white24,
          onChanged: (val) {
            setState(() => _ldrThreshold = val.toInt());
            HapticService.immersiveSliderFeedback(val, min: 0, max: 100);
          },
          onChangeEnd: (val) {
            HapticService.selection();
            _saveCurrentState();
          },
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              HapticService.impactClick();
              Navigator.pop(context);
            },
            child: Text(
              'Close',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDaytimeToggle() {
    final bool isDaytimeEnabled = _timeMode == 0;
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        setState(() {
          _timeMode = isDaytimeEnabled ? 4 : 0;
          if (_timeMode == 4) _ldrThreshold = 10;
          if (_timeMode == 0) _ldrThreshold = 0;
        });
        _saveCurrentState();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDaytimeEnabled
              ? Colors.cyanAccent.withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDaytimeEnabled
                ? Colors.cyanAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isDaytimeEnabled ? Icons.wb_sunny_rounded : Icons.nights_stay,
                  color: isDaytimeEnabled ? Colors.cyanAccent : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAYTIME MOTION",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isDaytimeEnabled ? Colors.white : Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      isDaytimeEnabled
                          ? "Triggers 24/7 (Always)"
                          : "Triggers Night Only (18:00 - 06:00)",
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: Colors.white30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            CupertinoSwitch(
              value: isDaytimeEnabled,
              onChanged: (val) {
                HapticService.heavy();
                setState(() {
                  _timeMode = val ? 0 : 4;
                  if (_timeMode == 4) _ldrThreshold = 10;
                  if (_timeMode == 0) _ldrThreshold = 0;
                });
                _saveCurrentState();
              },
              activeColor: Colors.cyanAccent,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildIndustrialModeSelector() {
    final modes = [
      {'label': 'Always', 'mode': 0, 'icon': Icons.all_inclusive, 'ldr': 0},
      {'label': 'Night 6-6', 'mode': 4, 'icon': Icons.nights_stay, 'ldr': 10},
      {'label': 'Noon', 'mode': 2, 'icon': Icons.wb_sunny_rounded, 'ldr': 40},
      {'label': 'Mid', 'mode': 3, 'icon': Icons.nightlight_round, 'ldr': 5},
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          // Animated Background Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
            alignment: Alignment(
              -1.0 +
                  (_timeMode != 0
                      ? (modes.indexWhere((m) => m['mode'] == _timeMode) /
                                (modes.length - 1)) *
                            2
                      : 0),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / modes.length,
              child:
                  Container(
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white10),
            ),
          ),
          // Clickable Icons/Labels
          Row(
            children: modes.map((m) {
              final isSelected = _timeMode == m['mode'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticService.heavy();
                    setState(() {
                      _timeMode = m['mode'] as int;
                      _ldrThreshold = m['ldr'] as int;
                    });
                    _saveCurrentState();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          m['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? Colors.cyanAccent
                              : Colors.white30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98));
  }
}
