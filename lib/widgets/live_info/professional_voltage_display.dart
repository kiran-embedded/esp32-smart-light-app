import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../core/ui/responsive_layout.dart';
import '../common/advanced_action_pills.dart';

class VoltagePillCard extends ConsumerWidget {
  const VoltagePillCard({super.key});

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

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * displaySettings.displayScale,
      ),
      child: AdvancedPillBase(
        icon: Icons.electric_meter_rounded,
        label: 'System Status',
        subtitle: '${voltage.toStringAsFixed(1)} VAC',
        color: voltageColor,
        onTap: () {},
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    voltage.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                      fontSize: (52 * displaySettings.displayScale).sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      shadows: [
                        BoxShadow(
                          color: voltageColor.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'V',
                      style: GoogleFonts.outfit(
                        fontSize: (20 * displaySettings.displayScale).sp,
                        fontWeight: FontWeight.w800,
                        color: voltageColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: voltageColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: voltageColor.withOpacity(0.3)),
                ),
                child: Text(
                  voltage < 180
                      ? 'CRITICAL'
                      : (voltage > 250 ? 'HIGH' : 'STABLE'),
                  style: GoogleFonts.outfit(
                    fontSize: (10 * displaySettings.displayScale).sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: voltageColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
