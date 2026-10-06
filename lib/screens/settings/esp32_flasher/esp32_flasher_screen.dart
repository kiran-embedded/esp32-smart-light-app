import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/haptic_service.dart';
import 'esp32_flasher_provider.dart';

class Esp32FlasherScreen extends ConsumerWidget {
  const Esp32FlasherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flasherProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1411) : const Color(0xFFF2FDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 32,
          ),
          onPressed: () {
            HapticService.light();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
              ).createShader(bounds),
              child: Text(
                'Firmware Flasher',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'Aurexa Core Generation & Export',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 24),
              _buildStep1(context, ref, state, isDark),
              const SizedBox(height: 24),
              _buildTerminal(state, isDark),
              const SizedBox(height: 24),
              _buildActionButtons(context, ref, state, isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGreen.withOpacity(0.15),
            AppTheme.neonGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neonGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.memory_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aurexa MCU Flasher',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure network settings and export the INO firmware script directly to Arduino IDE.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(
    BuildContext context,
    WidgetRef ref,
    FlasherState state,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B18) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.accentBlue),
                ),
                const SizedBox(width: 16),
                Text(
                  'Firmware Config',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          _buildInputField(
            icon: Icons.wifi_rounded,
            label: 'Wi-Fi SSID',
            value: state.wifiSsid.isEmpty ? 'Your_WiFi_Name' : state.wifiSsid,
            isDark: isDark,
            onChanged: (val) => ref.read(flasherProvider.notifier).updateConfig(ssid: val),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          _buildInputField(
            icon: Icons.lock_rounded,
            label: 'Wi-Fi Password',
            value: state.wifiPassword.isEmpty ? '••••••••' : state.wifiPassword,
            isDark: isDark,
            isPassword: true,
            onChanged: (val) => ref.read(flasherProvider.notifier).updateConfig(password: val),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          _buildInputField(
            icon: Icons.person_rounded,
            label: 'Device Username (ID)',
            value: state.username,
            isDark: isDark,
            onChanged: (val) => ref.read(flasherProvider.notifier).updateConfig(username: val),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.dashboard_rounded, color: AppTheme.neonGreen, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Relays',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Total hardware switches',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCounter(ref, state.switchCount, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal(FlasherState state, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), // GitHub dark dim
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Aurexa Build Output',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                if (state.isFlashing || state.progress > 0)
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
                    ),
                  )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                Color color = Colors.white;
                if (log.contains('✔') || log.contains('success')) color = AppTheme.neonGreen;
                if (log.contains('Error') || log.contains('Warning')) color = AppTheme.accentRed;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '> \$log',
                    style: GoogleFonts.firaCode(fontSize: 11, color: color, height: 1.4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    FlasherState state,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticService.heavy();
              ref.read(flasherProvider.notifier).generateFirmware();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_rounded, color: isDark ? Colors.white : Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Simulate Build',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticService.heavy();
              ref.read(flasherProvider.notifier).exportInoFile();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Export INO',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required ValueChanged<String> onChanged,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 24),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value,
              obscureText: isPassword,
              onChanged: onChanged,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Enter value',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(WidgetRef ref, int count, bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (count > 1) {
              HapticService.selection();
              ref.read(flasherProvider.notifier).updateConfig(switchCount: count - 1);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded, color: isDark ? Colors.white : Colors.black, size: 16),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (count < 8) {
              HapticService.selection();
              ref.read(flasherProvider.notifier).updateConfig(switchCount: count + 1);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: AppTheme.neonGreen, size: 16),
          ),
        ),
      ],
    );
  }
}
