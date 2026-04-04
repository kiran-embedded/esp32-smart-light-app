import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/display_settings_provider.dart';

class HeroVoltageMeter extends ConsumerWidget {
  final double scale;
  const HeroVoltageMeter({super.key, this.scale = 1.0});

  Color _getVoltageColor(double voltage) {
    if (voltage <= 0) return Colors.grey;
    if (voltage < 180) return Colors.redAccent;
    if (voltage < 200) return Colors.orangeAccent;
    if (voltage >= 200 && voltage <= 250) return Colors.greenAccent;
    if (voltage > 250) return Colors.redAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final voltage = liveInfo.acVoltage;
    final voltageColor = _getVoltageColor(voltage);
    final coreScale = displaySettings.displayScale * scale;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24 * coreScale),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 140 * coreScale,
            height: 140 * coreScale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: voltageColor.withOpacity(0.15),
                  blurRadius: 40 * coreScale,
                  spreadRadius: 10 * coreScale,
                ),
              ],
            ),
          ),

          // Voltage Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    voltage.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 74 * coreScale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12 * coreScale),
                    child: Text(
                      'V',
                      style: GoogleFonts.outfit(
                        fontSize: 24 * coreScale,
                        fontWeight: FontWeight.w800,
                        color: voltageColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'MAINS VOLTAGE',
                style: GoogleFonts.outfit(
                  fontSize: 10 * coreScale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white24,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
