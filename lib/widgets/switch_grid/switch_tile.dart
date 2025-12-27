import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/switch_device.dart';
import '../../services/haptic_service.dart';
import '../../providers/haptic_provider.dart';
import '../../services/device_icon_resolver.dart';
import 'neon_snake_border.dart';

class SwitchTile extends ConsumerStatefulWidget {
  final SwitchDevice device;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SwitchTile({
    super.key,
    required this.device,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  ConsumerState<SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends ConsumerState<SwitchTile>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _iconAnimController;
  late AnimationController _rippleController;

  late Animation<double> _pressAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _parallaxAnimation;

  bool _isInteracted = false;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pressAnimation = Tween<double>(
      begin: 0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));

    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutQuart,
    );

    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _parallaxAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.easeInOut),
    );
    _parallaxController.repeat(reverse: true);

    _updateIconAnimation();
  }

  late AnimationController _parallaxController;

  @override
  void didUpdateWidget(SwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.isActive != widget.device.isActive) {
      _updateIconAnimation();
    }
  }

  void _updateIconAnimation() {
    if (widget.device.isActive) {
      _iconAnimController.repeat();
    } else {
      _iconAnimController.stop();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _iconAnimController.dispose();
    _rippleController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    setState(() {
      _tapPosition = details.localPosition;
      _isInteracted = true;
    });

    _rippleController.forward(from: 0);
    HapticService.feedback(ref.read(hapticStyleProvider));

    await _pressController.forward();
    widget.onTap();
    await _pressController.reverse();

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isInteracted = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.device.isActive;
    final isConnected = widget.device.isConnected;

    // CRITICAL: Ensure nickname is prioritized for display AND icon resolution
    final String displayName =
        (widget.device.nickname != null && widget.device.nickname!.isNotEmpty)
        ? widget.device.nickname!
        : widget.device.name;

    // UNIQUE COLOR GENERATION: 7-Color style matching based on device ID
    // GUARANTEED DISTINCT COLORS for relay1...relay4
    Color uniqueColor;
    if (widget.device.id.toLowerCase().contains('relay1')) {
      uniqueColor = const Color(0xFF00FFFF); // Cyan
    } else if (widget.device.id.toLowerCase().contains('relay2')) {
      uniqueColor = const Color(0xFFFF00FF); // Magenta
    } else if (widget.device.id.toLowerCase().contains('relay3')) {
      uniqueColor = const Color(0xFF00FF00); // Green
    } else if (widget.device.id.toLowerCase().contains('relay4')) {
      uniqueColor = const Color(0xFFFFCC00); // Gold/Orange
    } else {
      // Fallback hash for others
      final int hueSeed = (widget.device.id.hashCode * 1337) ^ 0xDEADBEEF;
      final HSVColor uniqueHsv = HSVColor.fromAHSV(
        1.0,
        (hueSeed.abs() % 360).toDouble(),
        1.0, // High Saturation
        1.0, // Max Value
      );
      uniqueColor = uniqueHsv.toColor();
    }

    final iconInfo = DeviceIconResolver.resolve(displayName);

    return Padding(
      padding: const EdgeInsets.all(2), // Micro-margin to prevent edge ghosting
      child: LayoutBuilder(
        builder: (context, constraints) {
          // EXTREME SQUARE LOCK: Use the smaller of width/height constraints to define the side
          final double side = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : (constraints.maxHeight == double.infinity
                    ? constraints.maxWidth
                    : constraints.maxHeight);

          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pressController,
                    _iconAnimController,
                    _rippleController,
                    _parallaxController,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _pressAnimation.value),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    onLongPress: () {
                      HapticService.pulse();
                      widget.onLongPress();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: NeonSnakeBorder(
                        isActive: isActive,
                        isInteracted: _isInteracted,
                        isError: !isConnected,
                        borderRadius: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            children: [
                              _buildHardwareBody(
                                theme,
                                isActive,
                                widget.device.isPending, // Pending state
                                isConnected,
                                iconInfo,
                                displayName,
                                uniqueColor,
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _NeonRipplePainter(
                                      animation: _rippleAnimation,
                                      position: _tapPosition,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHardwareBody(
    ThemeData theme,
    bool isActive,
    bool isPending,
    bool isConnected,
    DeviceIconInfo iconInfo,
    String displayName,
    Color uniqueColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF151515),
        boxShadow: [
          // Outer deboss
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.9),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          // ACTIVE GLOW: Outer bloom
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 1,
            ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: AnimatedOpacity(
        // PENDING VISUAL: Pulse opacity slightly if pending
        duration: const Duration(milliseconds: 500),
        opacity: isPending ? 0.7 : 1.0,
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Glassy dark background when OFF, Vibrant gradient when ON
            color: isActive ? null : const Color(0xFF1A1A1A),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.5),
                      theme.colorScheme.primary.withOpacity(0.1),
                    ],
                  )
                : null,
            boxShadow: [
              // Inner inset for depth
              BoxShadow(
                color: isActive
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.04),
                offset: const Offset(-1, -1),
                blurRadius: 1,
              ),
            ],
          ),
          child: RepaintBoundary(
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // perspective
                ..translate(
                  _parallaxAnimation.value * 1.5,
                  _parallaxAnimation.value * 0.8,
                )
                ..rotateX(_parallaxAnimation.value * 0.02)
                ..rotateY(_parallaxAnimation.value * 0.02),
              alignment: Alignment.center,
              child: _buildRaisedCenter(
                theme,
                isActive,
                isConnected,
                iconInfo,
                displayName,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaisedCenter(
    ThemeData theme,
    bool isActive,
    bool isConnected,
    DeviceIconInfo iconInfo,
    String displayName,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Deep rich center
        color: isActive ? null : const Color(0xFF1F1F1F),
        gradient: isActive
            ? RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.white.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.3),
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [Color(0xFF2A2A2A), Color(0xFF151515)],
              ),
        boxShadow: [
          // Top Highlight
          BoxShadow(
            color: Colors.white.withOpacity(isActive ? 0.4 : 0.1),
            offset: const Offset(-1.5, -1.5),
            blurRadius: isActive ? 5 : 3,
          ),
          // Deep outer shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.95),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          // Inner Glow for Active State
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: -2,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: _buildAnimatedIcon(isActive, isConnected, theme, iconInfo),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12, // Slightly larger for better readability
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        shadows: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
                // REMOVED VOLTAGE TAG HERE
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(
    bool isActive,
    bool isConnected,
    ThemeData theme,
    DeviceIconInfo iconInfo,
  ) {
    Widget icon = Icon(
      isActive ? iconInfo.iconOn : iconInfo.iconOff,
      color: !isConnected
          ? Colors.orange.withOpacity(0.6)
          : (isActive
                ? theme.colorScheme.primary
                : Colors.white.withOpacity(
                    0.4,
                  )), // Boosted OFF visibility to 0.4
      size: 32,
    );

    if (!isActive) return icon;

    switch (iconInfo.animation) {
      case DeviceIconAnimation.rotating:
        return RotationTransition(turns: _iconAnimController, child: icon);
      case DeviceIconAnimation.blooming:
        return AnimatedBuilder(
          animation: _iconAnimController,
          builder: (context, child) {
            final scale = 1.0 + (0.15 * _iconAnimController.value);
            return Transform.scale(scale: scale, child: child);
          },
          child: icon,
        );
      case DeviceIconAnimation.pulsing:
        return AnimatedBuilder(
          animation: _iconAnimController,
          builder: (context, child) {
            final opacity = 0.5 + (0.5 * (1.0 - _iconAnimController.value));
            return Opacity(opacity: opacity, child: child);
          },
          child: icon,
        );
      default:
        return icon;
    }
  }
}

class _NeonRipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset position;
  final Color color;

  _NeonRipplePainter({
    required this.animation,
    required this.position,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0 || animation.value == 1) return;

    final progress = animation.value;
    final maxRadius = size.width * 1.2;
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // RGBW Infinite "Bubble" Effect
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          color.withOpacity(0.4 * opacity),
          Colors.cyan.withOpacity(0.3 * opacity),
          Colors.purple.withOpacity(0.2 * opacity),
          Colors.white.withOpacity(0.1 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: radius))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * (1 - progress));

    canvas.drawCircle(position, radius, paint);

    // Core Glow
    final Paint corePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(position, radius * 0.3, corePaint);
  }

  @override
  bool shouldRepaint(covariant _NeonRipplePainter oldDelegate) => true;
}
