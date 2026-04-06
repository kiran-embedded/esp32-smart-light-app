import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_switch_service.dart';
import '../../services/haptic_service.dart';
import '../../core/constants/app_constants.dart';
import 'dart:ui';

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
              color: const Color(0xFF111111).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: automationAsync.when(
              data: (data) {
                _loadFromData(data);
                return _buildContent();
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
                HapticService.selection();
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
                  HapticService.selection();
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
            // Moderate haptic based on duration
            HapticService.variableSelection(val / 300);
          },
          onChangeEnd: (val) {
            HapticService.selection();
            _saveCurrentState();
          },
        ),

        // TIME OF DAY PRESETS
        Text(
          'Environment Preset',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeModeChip('Morning', 70, Icons.wb_twilight, 1),
            _buildTimeModeChip('Day', 40, Icons.wb_sunny_rounded, 2),
            _buildTimeModeChip('Midnight', 5, Icons.nightlight_round, 3),
            _buildTimeModeChip('Always', _ldrThreshold, Icons.all_inclusive, 0),
          ],
        ),
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
            // Immersive haptic: vibrating harder as sensitivity increases
            HapticService.variableSelection(val / 100);
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
            onPressed: () => Navigator.pop(context),
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

  Widget _buildTimeModeChip(String label, int value, IconData icon, int mode) {
    final bool isSelected = _timeMode == mode;
    return GestureDetector(
      onTap: () {
        HapticService.heavy();
        setState(() {
          _ldrThreshold = value;
          _timeMode = mode;
        });
        _saveCurrentState();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.cyanAccent : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.cyanAccent : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
