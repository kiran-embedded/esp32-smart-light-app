import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/live_info_provider.dart';
import '../../providers/display_settings_provider.dart';
import '../../providers/switch_provider.dart';
import '../../core/ui/responsive_layout.dart';

class QuickActionTiles extends ConsumerWidget {
  const QuickActionTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInfo = ref.watch(liveInfoProvider);
    final displaySettings = ref.watch(displaySettingsProvider);
    final devices = ref.watch(switchDevicesProvider);
    final isConnected = devices.any((d) => d.isConnected);
    final scale = displaySettings.displayScale;

    // Power calculation (P = V * I)
    final power = liveInfo.acVoltage * liveInfo.current;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * scale,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              label: 'ENERGY',
              value: '${power.toStringAsFixed(0)}W',
              subValue: power > 0 ? 'Active Load' : 'Total Idle',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFFFD600),
              scale: scale,
              isPulsing: power > 0,
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: _ActionTile(
              label: 'HUB STATUS',
              value: isConnected ? 'ONLINE' : 'OFFLINE',
              subValue: isConnected ? 'Stable Linked' : 'Reconnecting',
              icon: isConnected ? Icons.router_rounded : Icons.wifi_off_rounded,
              color: isConnected ? const Color(0xFF00FAFF) : Colors.redAccent,
              scale: scale,
              showGlow: isConnected,
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: _ActionTile(
              label: 'SECURITY',
              value: 'ENCRYPT',
              subValue: 'AES-256 Bit',
              icon: Icons.security_rounded,
              color: const Color(0xFFBB86FC),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;
  final double scale;
  final bool isPulsing;
  final bool showGlow;

  const _ActionTile({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
    required this.scale,
    this.isPulsing = false,
    this.showGlow = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isPulsing || widget.showGlow) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ActionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing || widget.showGlow) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140 * widget.scale,
      padding: EdgeInsets.all(16 * widget.scale),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28 * widget.scale),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          if (widget.showGlow)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8 * widget.scale,
                    height: 8 * widget.scale,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(
                        0.5 * _pulseController.value,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(
                            0.3 * _pulseController.value,
                          ),
                          blurRadius: 10 * widget.scale,
                          spreadRadius: 2 * widget.scale,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10 * widget.scale),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20 * widget.scale,
                ),
              ),
              const Spacer(),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 10 * widget.scale,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.value,
                  style: GoogleFonts.outfit(
                    fontSize: 20 * widget.scale,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subValue,
                style: GoogleFonts.outfit(
                  fontSize: 9 * widget.scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.25),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
