import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/live_info_provider.dart';
import '../common/frosted_glass.dart';

class LiveInfoHUD extends ConsumerWidget {
  const LiveInfoHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: FrostedGlass(
        padding: const EdgeInsets.all(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        child: Column(
          children: [
            // Time and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 12-Hour Format with AM/PM
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          DateFormat('hh:mm').format(liveInfo.currentTime),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('a').format(liveInfo.currentTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(liveInfo.currentTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                // Weather
                Row(
                  children: [
                    _buildWeatherIcon(liveInfo.weatherIcon, theme),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${liveInfo.temperature.toStringAsFixed(1)}°C',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          liveInfo.weatherDescription,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Separator
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Voltage and Current
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  context,
                  'AC Voltage',
                  '${liveInfo.acVoltage.toStringAsFixed(1)} V',
                  Icons.bolt,
                  theme,
                ),
                _buildMetric(
                  context,
                  'Current',
                  '${liveInfo.current.toStringAsFixed(2)} A',
                  Icons.electric_bolt,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(String iconCode, ThemeData theme) {
    // Map emoji/string to beautiful icons
    IconData icon;
    Color color;

    // Default based on time if iconCode is generic
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 18;

    if (iconCode.contains('☁') || iconCode.contains('Cloud')) {
      icon = isNight ? Icons.nightlight_round : Icons.cloud;
      color = isNight ? Colors.purpleAccent : Colors.lightBlueAccent;
    } else if (iconCode.contains('🌧') || iconCode.contains('Rain')) {
      icon = Icons.water_drop;
      color = Colors.blue;
    } else if (iconCode.contains('❄') || iconCode.contains('Snow')) {
      icon = Icons.ac_unit;
      color = Colors.cyan;
    } else {
      // Default Sun/Moon
      icon = isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;
      color = isNight ? Colors.amberAccent : Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
