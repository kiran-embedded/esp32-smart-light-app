import 'package:flutter/material.dart';
import '../common/frosted_glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/pixel_led_border.dart';
import 'package:flutter/services.dart';

class StatusCard extends StatefulWidget {
  final double voltage;
  final String systemState;

  const StatusCard({
    super.key,
    required this.voltage,
    required this.systemState,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVoltageNormal = widget.voltage > 200 && widget.voltage < 250;
    final voltageColor = isVoltageNormal
        ? Colors.greenAccent
        : (widget.voltage > 250 ? Colors.redAccent : Colors.amberAccent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Left Block: Voltage
          Expanded(
                child: RepaintBoundary(
                  child: PixelLedBorder(
                    enableInfiniteRainbow: true, // RGB infinite look
                    strokeWidth: 1.5, // Thinner neon tube
                    duration: const Duration(
                      seconds: 4,
                    ), // Smooth, slower snake
                    colors: const [], // Ignored when rainbow enabled
                    child: FrostedGlass(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                    Icons.electric_bolt_rounded,
                                    color: voltageColor,
                                    size: 20,
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(duration: 1200.ms),
                              const SizedBox(width: 8),
                              Text(
                                'AC VOLTAGE',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: widget.voltage < 180
                                ? [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'MAINS CUT OFF',
                                          style: GoogleFonts.ruda(
                                            // Technical, serious font
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.redAccent,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    Text(
                                      widget.voltage.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'V',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 2,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              gradient: LinearGradient(
                                colors: [voltageColor, Colors.transparent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: voltageColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .slideX(
                begin: -1.0,
                end: 0,
                duration: 800.ms,
                curve: Curves.elasticOut,
              )
              .callback(callback: (_) => HapticFeedback.mediumImpact()),

          const SizedBox(width: 12),

          // Right Block: Status
          Expanded(
                child: RepaintBoundary(
                  child: PixelLedBorder(
                    enableInfiniteRainbow: true,
                    strokeWidth: 1.5,
                    duration: const Duration(
                      seconds: 5,
                    ), // Slightly different speed
                    colors: const [],
                    child: FrostedGlass(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SYSTEM STATUS',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.systemState,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // High-Performance Shimmer Bar
                          SizedBox(
                            height: 2,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      widthFactor: 1.0,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final xOffset =
                                              constraints.maxWidth *
                                                  _shimmerController.value *
                                                  1.5 -
                                              (constraints.maxWidth * 0.5);
                                          return Transform.translate(
                                            offset: Offset(xOffset, 0),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(1),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withOpacity(
                                            0.0,
                                          ),
                                          theme.colorScheme.primary.withOpacity(
                                            0.8,
                                          ),
                                          theme.colorScheme.primary.withOpacity(
                                            0.0,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.4),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .slideX(
                begin: 1.0,
                end: 0,
                duration: 800.ms,
                curve: Curves.elasticOut,
              )
              .callback(callback: (_) => HapticFeedback.mediumImpact()),
        ],
      ),
    );
  }
}
