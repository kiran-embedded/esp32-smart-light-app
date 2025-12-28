import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/switch_device.dart';
import '../../services/haptic_service.dart';
import '../../providers/haptic_provider.dart';
import '../../services/device_icon_resolver.dart';
import '../../core/ui/adaptive_text_engine.dart';
import '../../providers/switch_style_provider.dart';
import 'dart:math' as math; // For Cyberpunk jitter
import 'dart:ui'; // For blur effects

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
  late AnimationController _rgbController; // New for Gaming RGB

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

    _rgbController = AnimationController(
      // New
      vsync: this,
      duration: const Duration(seconds: 3),
    ); // Removed ..repeat() for performance

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
    _rgbController.dispose(); // New
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
    final style = ref.watch(switchStyleProvider); // WATCH STYLE

    // Performance Optimization: Only run RGB ticker if style is Gaming RGB
    if (style == SwitchStyleType.gamingRGB) {
      if (!_rgbController.isAnimating) _rgbController.repeat();
    } else {
      if (_rgbController.isAnimating) _rgbController.stop();
    }

    // Common calculations
    final String displayName =
        (widget.device.nickname != null && widget.device.nickname!.isNotEmpty)
        ? widget.device.nickname!
        : widget.device.name;

    Color uniqueColor;
    if (widget.device.id.toLowerCase().contains('relay1')) {
      uniqueColor = const Color(0xFF00FFFF);
    } else if (widget.device.id.toLowerCase().contains('relay2')) {
      uniqueColor = const Color(0xFFFF00FF);
    } else if (widget.device.id.toLowerCase().contains('relay3')) {
      uniqueColor = const Color(0xFF00FF00);
    } else if (widget.device.id.toLowerCase().contains('relay4')) {
      uniqueColor = const Color(0xFFFFCC00);
    } else {
      final int hueSeed = (widget.device.id.hashCode * 1337) ^ 0xDEADBEEF;
      final HSVColor uniqueHsv = HSVColor.fromAHSV(
        1.0,
        (hueSeed.abs() % 360).toDouble(),
        1.0,
        1.0,
      );
      uniqueColor = uniqueHsv.toColor();
    }
    final Color contentColor = uniqueColor.adaptiveContentColor;
    final iconInfo = DeviceIconResolver.resolve(displayName);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double side = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : (constraints.maxHeight == double.infinity
                    ? constraints.maxWidth
                    : constraints.maxHeight);

          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onLongPress: () {
                  HapticService.pulse();
                  widget.onLongPress();
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pressController,
                    _iconAnimController,
                    _rippleController,
                    _parallaxController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 - (_pressController.value * 0.05),
                      child: _buildStyleDispatcher(
                        style,
                        theme,
                        displayName,
                        uniqueColor,
                        contentColor,
                        iconInfo,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleDispatcher(
    SwitchStyleType style,
    ThemeData theme,
    String displayName,
    Color uniqueColor,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    switch (style) {
      case SwitchStyleType.modern:
        return _buildModernStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.fluid:
        return _buildFluidStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.realistic:
        return _buildRealisticStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.different:
        return _buildDifferentStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.smooth:
        return _buildSmoothStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.neonGlass:
        return _buildNeonGlassStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.industrialMetallic:
        return _buildIndustrialStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
      case SwitchStyleType.gamingRGB:
        return _buildGamingRGBStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
        );
    }
  }

  // 1. MODERN STYLE: Clean, Minimal, High Contrast
  Widget _buildModernStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _iconAnimController,
                builder: (context, child) => Transform.scale(
                  scale: isActive ? 1.1 : 1.0,
                  child: Icon(
                    isActive ? iconInfo.iconOn : iconInfo.iconOff,
                    color: isActive
                        ? contentColor
                        : Colors.white.withOpacity(0.5),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.toUpperCase(),
                style: GoogleFonts.inter(
                  color: isActive ? contentColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. FLUID STYLE: Organic, Liquid Animation
  Widget _buildFluidStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Liquid Background
              AnimatedAlign(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                alignment: isActive ? Alignment.center : Alignment.bottomLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutBack,
                  width: isActive ? 400 : 20, // Overseized to fill
                  height: isActive ? 400 : 20,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isActive ? 1.0 : 0.0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedIcon(
                      isActive,
                      widget.device.isConnected,
                      isActive ? contentColor : color,
                      isActive ? contentColor : color,
                      iconInfo,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: isActive
                            ? contentColor
                            : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. REALISTIC STYLE: Skeuomorphic, bevels, depth
  Widget _buildRealisticStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF353535), const Color(0xFF252525)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F1F1F),
              boxShadow: [
                // Inset shadow uses opposite offsets for pressed effect
                BoxShadow(
                  color: isActive
                      ? Colors.black.withOpacity(0.8)
                      : Colors.black.withOpacity(0.5),
                  offset: isActive ? const Offset(3, 3) : const Offset(2, 2),
                  blurRadius: isActive ? 4 : 6,
                  spreadRadius: 0,
                  // Note: standard BoxShadow doesn't support 'inset', so we fake it with darkness or layers.
                  // For true inset, we usually need custom painters, but here we just dampen the light.
                ),
                if (isActive)
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                if (!isActive)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                isActive ? iconInfo.iconOn : iconInfo.iconOff,
                color: isActive ? color : Colors.grey,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. DIFFERENT (CYBERPUNK): Glitch, Raw, Technical
  Widget _buildDifferentStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: isActive ? color : const Color(0xFF333333),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Code-based Glitch Background (No Network Image)
            if (isActive)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CyberpunkGlitchPainter(color: color),
                ),
              ),

            // Technical decorative corners
            Positioned(
              top: 4,
              left: 4,
              child: Container(width: 4, height: 4, color: color),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(width: 4, height: 4, color: color),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STATUS::${isActive ? 'ACTV' : 'STBY'}",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10,
                      color: isActive ? color : Colors.white.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Glitch scale effect for icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: isActive ? 1.05 : 1.0),
                    duration: const Duration(milliseconds: 100),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale:
                            scale +
                            (isActive
                                ? (math.Random().nextDouble() * 0.05)
                                : 0),
                        child: Icon(
                          isActive ? iconInfo.iconOn : iconInfo.iconOff,
                          color: isActive
                              ? color
                              : Colors.white.withOpacity(0.3),
                          size: 32,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  Text(
                    name.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isActive ? color : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      shadows: isActive
                          ? [BoxShadow(color: color, blurRadius: 10)]
                          : [],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. SMOOTH (NEUMORPHIC): Soft, matte, gentle
  Widget _buildSmoothStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;
    // Neumorphic colors
    final baseColor = isActive ? color : const Color(0xFFE0E5EC);

    // Calculate shadow colors based on baseColor
    final hsl = HSLColor.fromColor(baseColor);
    final lightShadow = hsl
        .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
        .toColor();
    final darkShadow = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: darkShadow.withOpacity(0.5),
              offset: isActive ? const Offset(2, 2) : const Offset(6, 6),
              blurRadius: isActive ? 4 : 12,
            ),
            BoxShadow(
              color: lightShadow,
              offset: isActive ? const Offset(-2, -2) : const Offset(-6, -6),
              blurRadius: isActive ? 4 : 12,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? iconInfo.iconOn : iconInfo.iconOff,
                color: isActive ? contentColor : const Color(0xFFA3B1C6),
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.nunito(
                  color: isActive ? contentColor : const Color(0xFFA3B1C6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. NEON GLASS: Premium Frosted, Sharp Edges
  Widget _buildNeonGlassStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Frosted Blur Base
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: isActive
                    ? color.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
              ),
            ),

            // Dynamic Border & Fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : Colors.white.withOpacity(0.2),
                  width: isActive ? 2 : 1,
                ),
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.4),
                          color.withOpacity(0.1),
                        ],
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedIcon(
                      isActive,
                      widget.device.isConnected,
                      color,
                      isActive ? Colors.white : Colors.white,
                      iconInfo,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name.toUpperCase(),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        shadows: isActive
                            ? [BoxShadow(color: color, blurRadius: 10)]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. INDUSTRIAL: Brushed metal, Screws, Mechanical
  Widget _buildIndustrialStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Sharper corners
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A4A4A),
              const Color(0xFF2B2B2B),
              const Color(0xFF1A1A1A),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(3, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFF555555), width: 1),
        ),
        child: Stack(
          children: [
            // Screws
            for (var align in [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: align,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.grey, Colors.black],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 1,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // LED Indicator
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : const Color(0xFF330000),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
              ),
            ),

            // Toggle Switch
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF222222)
                          : const Color(0xFF181818),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isActive ? iconInfo.iconOn : iconInfo.iconOff,
                      color: isActive ? color : Colors.white.withOpacity(0.2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. GAMING RGB: Rotating Chroma Border
  Widget _buildGamingRGBStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    final isActive = widget.device.isActive;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rgbController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(3), // Border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
                transform: GradientRotation(_rgbController.value * 2 * math.pi),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: -2,
                      ),
                    ]
                  : [],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? iconInfo.iconOn : iconInfo.iconOff,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      size: 34,
                      shadows: isActive
                          ? [
                              const BoxShadow(
                                color: Colors.cyanAccent,
                                blurRadius: 10,
                              ),
                              BoxShadow(
                                color: Colors.purpleAccent,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ]
                          : [],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // REUSABLE ICON BUILDER FOR SOME STYLES
  Widget _buildAnimatedIcon(
    bool isActive,
    bool isConnected,
    Color uniqueColor,
    Color contentColor,
    DeviceIconInfo iconInfo,
  ) {
    Widget icon = Icon(
      isActive ? iconInfo.iconOn : iconInfo.iconOff,
      color: !isConnected
          ? Colors.orange.withOpacity(0.6)
          : (isActive
                ? contentColor // ADAPTIVE COLOR
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

class _CyberpunkGlitchPainter extends CustomPainter {
  final Color color;
  _CyberpunkGlitchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final random = math.Random();

    // Draw random horizontal scanlines
    for (int i = 0; i < 5; i++) {
      final y = random.nextDouble() * size.height;
      final h = random.nextDouble() * 5 + 1;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
    }

    // Draw random block noise
    for (int i = 0; i < 3; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = random.nextDouble() * 50 + 10;
      final h = random.nextDouble() * 20 + 2;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for glitch effect
}
