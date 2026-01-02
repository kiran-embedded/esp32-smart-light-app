import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/switch_device.dart';
import '../../services/haptic_service.dart';
import '../../providers/haptic_provider.dart';
import '../../services/device_icon_resolver.dart';
import '../../core/ui/adaptive_text_engine.dart';
import '../../providers/switch_style_provider.dart';
import '../../providers/switch_settings_provider.dart';
import '../../providers/performance_provider.dart'; // Added
import '../../core/ui/responsive_layout.dart';
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

    // Dynamic Blending Setting
    final performanceMode = ref.watch(performanceProvider);
    // If Performance Mode is ON, force blending OFF to save GPU
    final blendingEnabled =
        !performanceMode && ref.watch(switchSettingsProvider).dynamicBlending;

    // Performance Optimization: Stop heavy animations if in Performance Mode
    if (performanceMode) {
      if (_rgbController.isAnimating) _rgbController.stop();
      if (_parallaxController.isAnimating) _parallaxController.stop();
    } else {
      // Only run RGB ticker if style is Gaming RGB
      if (style == SwitchStyleType.gamingRGB) {
        if (!_rgbController.isAnimating) _rgbController.repeat();
      } else {
        if (_rgbController.isAnimating) _rgbController.stop();
      }

      // Restore Parallax if not playing
      if (!_parallaxController.isAnimating)
        _parallaxController.repeat(reverse: true);
    }
    // isOffTransparent variable removed as it was unused locally

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
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.8,
                              ), // Deep projection
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                              spreadRadius: -15,
                            ),
                          ],
                        ),
                        child: _buildStyleDispatcher(
                          style,
                          theme,
                          displayName,
                          uniqueColor,
                          contentColor,
                          iconInfo,
                          blendingEnabled, // Pass blending flag
                        ),
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
    bool blendingEnabled,
  ) {
    switch (style) {
      case SwitchStyleType.modern:
        return _buildModernStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.fluid:
        return _buildFluidStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled, // Added support
        );
      case SwitchStyleType.realistic:
        return _buildRealisticStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled, // Added support
        );
      // Pass blendingEnabled to other styles if needed, currently focusing on key ones for impact
      case SwitchStyleType.different:
        return _buildDifferentStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.smooth:
        return _buildSmoothStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.neonGlass:
        return _buildNeonGlassStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.industrialMetallic:
        return _buildIndustrialStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.gamingRGB:
        return _buildGamingRGBStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.holographic:
        return _buildHolographicStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.liquidMetal:
        return _buildLiquidMetalStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.quantumDot:
        return _buildQuantumDotStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.cosmicPulse:
        return _buildCosmicPulseStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.retroVapor:
        return _buildRetroVaporStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.bioOrganic:
        return _buildBioOrganicStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.crystalPrism:
        return _buildCrystalPrismStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.voidAbyss:
        return _buildVoidAbyssStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.solarFlare:
        return _buildSolarFlareStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.electricTundra:
        return _buildElectricTundraStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.nanoCatalyst:
        return _buildNanoCatalystStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.phantomVelvet:
        return _buildPhantomVelvetStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.prismFractal:
        return _buildPrismFractalStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.magmaCore:
        return _buildMagmaCoreStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.cyberBloom:
        return _buildCyberBloomStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.voidRift:
        return _buildVoidRiftStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.starlightEcho:
        return _buildStarlightEchoStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
        );
      case SwitchStyleType.aeroStream:
        return _buildAeroStreamStyle(
          theme,
          displayName,
          uniqueColor,
          contentColor,
          iconInfo,
          blendingEnabled,
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
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    final isLight = theme.brightness == Brightness.light;

    // Transparent if blending is enabled and switch is OFF
    final offColor = blendingEnabled && !isActive
        ? (isLight
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.3)) // Frosted Glass tint
        : (isLight ? Colors.white.withOpacity(0.6) : const Color(0xFF1E1E1E));

    // If blending enabled and Active, add a bit of transparency/glass
    final effectiveColor = (blendingEnabled && isActive)
        ? color.withOpacity(0.85) // Slight see-through for active
        : color;

    final borderColor = isActive
        ? Colors.transparent
        : (isLight
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.1));

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive ? effectiveColor : offColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        // Reduce shadow opacity if blending to let background shine
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : (isLight || blendingEnabled
                  ? [
                      // Soft shadow for off state in light mode OR blending
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : []),
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
                      : (isLight
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.5)),
                  size: 40.r,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name.toUpperCase(),
              style: GoogleFonts.inter(
                color: isActive
                    ? contentColor
                    : (isLight ? Colors.black.withOpacity(0.8) : Colors.white),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 2. FLUID STYLE: Organic, Liquid Animation
  Widget _buildFluidStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          // Transparent base if blending
          color: blendingEnabled
              ? Colors.white.withOpacity(0.02)
              : Colors.black,
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
                    color: color.withOpacity(
                      isActive ? (blendingEnabled ? 0.8 : 1.0) : 0.0,
                    ),
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
                    SizedBox(height: 12.h),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: isActive
                            ? contentColor
                            : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
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
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (Colors.black.withOpacity(0.3)) // Darker tint for glass
            : const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        gradient: blendingEnabled
            ? LinearGradient(
                // Subtle glass gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              )
            : LinearGradient(
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
          if (!blendingEnabled) // Only show highlight reflection if opaque
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          if (blendingEnabled) // Glass edge highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blendingEnabled
                ? (isActive
                      ? const Color(0xFF1F1F1F).withOpacity(0.8)
                      : Colors.black.withOpacity(0.2))
                : const Color(0xFF1F1F1F),
            boxShadow: [
              // Inset shadow uses opposite offsets for pressed effect
              BoxShadow(
                color: isActive
                    ? Colors.black.withOpacity(0.8)
                    : Colors.black.withOpacity(0.5),
                offset: isActive ? const Offset(3, 3) : const Offset(2, 2),
                blurRadius: isActive ? 4 : 6,
                spreadRadius: 0,
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
              size: 30.r,
            ),
          ),
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 4. DIFFERENT (CYBERPUNK): Glitch, Raw, Technical
  Widget _buildDifferentStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.black.withOpacity(0.9)
                  : Colors.black.withOpacity(0.3))
            : Colors.black,
        border: Border.all(
          color: isActive
              ? color
              : (blendingEnabled
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF333333)),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Code-based Glitch Background (No Network Image)
          if (isActive && !blendingEnabled)
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
                          (isActive ? (math.Random().nextDouble() * 0.05) : 0),
                      child: Icon(
                        isActive ? iconInfo.iconOn : iconInfo.iconOff,
                        color: isActive ? color : Colors.white.withOpacity(0.3),
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
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 5. SMOOTH (NEUMORPHIC): Soft, matte, gentle
  Widget _buildSmoothStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    // Neumorphic colors
    final baseColor = blendingEnabled
        ? (isActive
              ? color.withOpacity(0.9)
              : Colors.white.withOpacity(0.1)) // More visible glass
        : (isActive ? color : const Color(0xFFE0E5EC));

    Color lightShadow = Colors.transparent;
    Color darkShadow = Colors.transparent;

    if (!blendingEnabled) {
      final hsl = HSLColor.fromColor(
        isActive ? color : const Color(0xFFE0E5EC),
      );
      lightShadow = hsl
          .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
          .toColor();
      darkShadow = hsl
          .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
          .toColor();
    }

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(24),
        border: blendingEnabled
            ? Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ) // Glass border
            : null,
        boxShadow: blendingEnabled
            ? [
                // Glassmorphism shadows
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ]
            : [
                BoxShadow(
                  color: darkShadow.withOpacity(0.5),
                  offset: isActive ? const Offset(2, 2) : const Offset(6, 6),
                  blurRadius: isActive ? 4 : 12,
                ),
                BoxShadow(
                  color: lightShadow,
                  offset: isActive
                      ? const Offset(-2, -2)
                      : const Offset(-6, -6),
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
              size: 36.r,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.nunito(
                color: isActive ? contentColor : const Color(0xFFA3B1C6),
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }

    return RepaintBoundary(child: container);
  }

  // 6. NEON GLASS: Premium Frosted, Sharp Edges
  Widget _buildNeonGlassStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    // Neon glass already has some transparency, but we can enhance it
    final bgOpacity = blendingEnabled
        ? (isActive ? 0.15 : 0.02)
        : (isActive ? 0.2 : 0.05);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Frosted Blur Base
            // Frosted Blur Base (Optimized: Removed Blur)
            Container(
              color: isActive
                  ? color.withOpacity(bgOpacity)
                  : Colors.white.withOpacity(bgOpacity),
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
                    SizedBox(height: 10.h),
                    Text(
                      name.toUpperCase(),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        letterSpacing: 1.2.w,
                        shadows: isActive
                            ? [BoxShadow(color: color, blurRadius: 10.r)]
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
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // Sharper corners
        gradient: (!blendingEnabled)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A4A4A),
                  const Color(0xFF2B2B2B),
                  const Color(0xFF1A1A1A),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : null,
        color: blendingEnabled ? Colors.black.withOpacity(0.4) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(3, 3),
            blurRadius: 5,
          ),
          if (!blendingEnabled)
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
          if (blendingEnabled) // Glass highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
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
                  width: 6.r,
                  height: 6.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
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
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : const Color(0xFF330000),
                boxShadow: isActive
                    ? [BoxShadow(color: color, blurRadius: 6, spreadRadius: 2)]
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
                    size: 28.r,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 8. GAMING RGB: Rotating Chroma Border
  Widget _buildGamingRGBStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rgbController,
        builder: (context, child) {
          final borderCol = isActive
              ? Colors.transparent
              : (blendingEnabled
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent);

          Widget container = Container(
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
                color: blendingEnabled
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black,
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
                      size: 34.r,
                      shadows: isActive
                          ? [
                              BoxShadow(
                                color: Colors.cyanAccent,
                                blurRadius: 10.r,
                              ),
                              BoxShadow(
                                color: Colors.purpleAccent,
                                blurRadius: 10.r,
                                offset: Offset(2.w, 2.h),
                              ),
                            ]
                          : [],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          if (blendingEnabled) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(children: [const SizedBox.shrink(), container]),
            );
          }
          return container;
        },
      ),
    );
  }

  // 9. HOLOGRAPHIC (PRO): Futuristic Projection
  Widget _buildHolographicStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Stack(
      children: [
        // Base
        Container(
          decoration: BoxDecoration(
            color: blendingEnabled
                ? (isActive
                      ? Colors.black.withOpacity(0.8)
                      : Colors.black.withOpacity(0.2))
                : Colors.black,
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.8)
                  : (blendingEnabled
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white10),
              width: 1,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isActive ? 4 : 16),
              bottomRight: Radius.circular(isActive ? 4 : 16),
            ),
          ),
        ),
        // Hologram Projection
        if (isActive)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: _HologramGridPainter(color: color)),
            ),
          ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glitchy Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 100),
                builder: (context, value, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [color, Colors.white, color],
                      stops: [0, 0.5, 1],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(
                        _iconAnimController.value * 6.28,
                      ),
                    ).createShader(bounds),
                    child: Icon(
                      isActive ? iconInfo.iconOn : iconInfo.iconOff,
                      size: 38.r,
                      color: Colors.white, // Mask handles color
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                name.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: isActive
                      ? color
                      : (blendingEnabled
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white54),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  letterSpacing: 3.w,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isActive ? 4 : 16),
            bottomRight: Radius.circular(isActive ? 4 : 16),
          ),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 10. LIQUID METAL: Chrome, Reflective
  Widget _buildLiquidMetalStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: blendingEnabled
            ? (isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05))
            : null,
        gradient: (!blendingEnabled)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [
                        const Color(0xFFE0E0E0),
                        const Color(0xFF9E9E9E),
                        const Color(0xFF616161),
                      ]
                    : [const Color(0xFF424242), const Color(0xFF212121)],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? color.withOpacity(0.6)
                : (blendingEnabled
                      ? Colors.black.withOpacity(0.1)
                      : Colors.black45),
            blurRadius: isActive ? 20 : 5,
            spreadRadius: isActive ? 2 : 0,
          ),
        ],
        border: blendingEnabled
            ? Border.all(color: Colors.white.withOpacity(0.2))
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(color: color.withOpacity(0.1)),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedIcon(
                isActive,
                widget.device.isConnected,
                blendingEnabled
                    ? (isActive ? Colors.white : Colors.white70)
                    : Colors.black, // Dark icon on metal, Light on glass
                isActive
                    ? (blendingEnabled ? Colors.white : Colors.black87)
                    : Colors.white24,
                iconInfo,
              ),
              const SizedBox(height: 5),
              Text(
                name,
                style: GoogleFonts.exo2(
                  color: isActive
                      ? (blendingEnabled ? Colors.white : Colors.black87)
                      : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 11. QUANTUM DOT: Particles
  Widget _buildQuantumDotStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Stack(
      children: [
        Container(
          color: blendingEnabled
              ? Colors.black.withOpacity(0.2)
              : const Color(0xFF050505),
        ),
        if (isActive)
          Positioned.fill(
            child: CustomPaint(
              painter: _QuantumDotPainter(
                color: color,
                animation: _iconAnimController,
              ),
            ),
          ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? color
                        : (blendingEnabled
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white10),
                    width: 2.w,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: color, blurRadius: 15.r)]
                      : [],
                ),
                child: Center(
                  child: Icon(
                    isActive ? iconInfo.iconOn : iconInfo.iconOff,
                    color: isActive ? Colors.white : Colors.white24,
                    size: 28.r,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), // Approx radius
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 12. COSMIC PULSE: Galaxy, Stars, Rotation
  Widget _buildCosmicPulseStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: blendingEnabled
                ? (isActive
                      ? Colors.black.withOpacity(0.8)
                      : Colors.black.withOpacity(0.2))
                : const Color(0xFF08081A),
            image: (!blendingEnabled)
                ? const DecorationImage(
                    image: AssetImage('assets/images/nebula_bg_1.jpg'),
                    fit: BoxFit.cover,
                    opacity: 0.4,
                  )
                : null,
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.5)
                  : (blendingEnabled
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white10),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ]
                : [],
          ),
        ),
        if (isActive)
          Positioned.fill(
            child: RotationTransition(
              turns: _iconAnimController,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      color.withOpacity(0),
                      color.withOpacity(0.5),
                      color.withOpacity(0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
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
                color,
                Colors.white,
                iconInfo,
              ),
              SizedBox(height: 8.h),
              Text(
                name,
                style: GoogleFonts.audiowide(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 13. RETRO VAPOR: 80s Grid, Sun
  Widget _buildRetroVaporStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: (!blendingEnabled)
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E003E), Color(0xFFFF007A)],
              )
            : null,
        color: blendingEnabled
            ? (isActive
                  ? Colors.black.withOpacity(0.8)
                  : Colors.black.withOpacity(0.3))
            : null,
        border: Border.all(
          color: isActive
              ? Colors.cyanAccent
              : (blendingEnabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.cyanAccent),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Grid
          Positioned.fill(
            child: Opacity(
              opacity: blendingEnabled ? 0.5 : 1.0,
              child: CustomPaint(
                painter: _HologramGridPainter(color: Colors.cyanAccent),
              ),
            ),
          ),
          // Sun
          if (isActive)
            Positioned(
              bottom: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.yellow, Colors.orange, Colors.red],
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? iconInfo.iconOn : iconInfo.iconOff,
                  color: Colors.cyanAccent,
                  size: 30.r,
                ),
                SizedBox(height: 5.h),
                Text(
                  name,
                  style: GoogleFonts.vt323(
                    color: Colors.yellowAccent,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 14. BIO ORGANIC: Breathing, blobs
  Widget _buildBioOrganicStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2))
            : (isActive ? color.withOpacity(0.2) : Colors.grey[900]),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
          topRight: Radius.circular(isActive ? 40 : 10),
          bottomLeft: Radius.circular(isActive ? 40 : 10),
        ),
        border: Border.all(
          color: isActive
              ? color
              : (blendingEnabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[800]!),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _iconAnimController, // Breathing
              child: Icon(
                isActive ? iconInfo.iconOn : iconInfo.iconOff,
                color: isActive ? color : Colors.grey,
                size: 34.r,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.comfortaa(
                color: isActive ? color : Colors.grey,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
            topRight: Radius.circular(isActive ? 40 : 10),
            bottomLeft: Radius.circular(isActive ? 40 : 10),
          ),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 15. CRYSTAL PRISM: Refractive Glass
  Widget _buildCrystalPrismStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    // For Crystal Prism, we adjust the base darkness when blending to be more "frosted".
    // It is already glassy, so we just enhance the background blur.

    Widget container = Stack(
      children: [
        Container(
          color: blendingEnabled ? Colors.black.withOpacity(0.0) : Colors.black,
        ), // OFF = Transparent logic base
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      colors: [Colors.blue, Colors.purple, Colors.pink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect),
                    child: Icon(
                      isActive ? iconInfo.iconOn : iconInfo.iconOff,
                      color: Colors.white,
                      size: 36.r,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    name,
                    style: GoogleFonts.geo(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isActive)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 16. VOID ABYSS: Minimal Dark
  Widget _buildVoidAbyssStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.black.withOpacity(0.9)
                  : Colors.black.withOpacity(0.4))
            : Colors.black,
        boxShadow: isActive
            ? [BoxShadow(color: color, blurRadius: 30, spreadRadius: -10)]
            : [],
        shape: BoxShape.circle,
        border: blendingEnabled
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? Colors.white : Colors.white24,
              size: 30.r,
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipOval(
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 17. SOLAR FLARE: Corona, Heat
  Widget _buildSolarFlareStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    final t = _iconAnimController.value;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? color.withOpacity(0.8)
                  : Colors.black.withOpacity(0.3))
            : (isActive ? color : Colors.black),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.8)
              : color.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 30 + math.sin(t * 2 * math.pi) * 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? Colors.white : color.withOpacity(0.5),
              size: 36.r,
            ),
            SizedBox(height: 4.h),
            Text(
              name.toUpperCase(),
              style: GoogleFonts.outfit(
                color: isActive ? Colors.white : color.withOpacity(0.8),
                fontWeight: FontWeight.w900,
                fontSize: 10.sp,
                letterSpacing: 1.5.w,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 18. ELECTRIC TUNDRA: Icy, Bolts
  Widget _buildElectricTundraStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.05))
            : (isActive ? const Color(0xFF001F3F) : Colors.black),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.cyanAccent : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          if (isActive)
            Positioned.fill(
              child: CustomPaint(
                painter: _CyberpunkGlitchPainter(color: Colors.cyanAccent),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? iconInfo.iconOn : iconInfo.iconOff,
                  color: isActive ? Colors.cyanAccent : Colors.white38,
                  size: 32.r,
                ),
                Text(
                  name,
                  style: GoogleFonts.rajdhani(
                    color: isActive ? Colors.white : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 19. NANO CATALYST: Hex Assembly
  Widget _buildNanoCatalystStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(blendingEnabled ? 0.3 : 0.9)
            : (blendingEnabled ? Colors.black.withOpacity(0.2) : Colors.black),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.white : color.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? Colors.white : color.withOpacity(0.5),
              size: 30.r,
            ),
            Text(
              "NANO::${isActive ? 'ON' : 'OFF'}",
              style: GoogleFonts.shareTechMono(
                color: isActive ? Colors.white : color.withOpacity(0.4),
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 20. PHANTOM VELVET: Smoky, Smooth
  Widget _buildPhantomVelvetStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: !isActive
            ? (blendingEnabled ? Colors.purple.withOpacity(0.1) : Colors.black)
            : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive
                  ? Colors.white
                  : Colors.purpleAccent.withOpacity(0.3),
              size: 34.r,
            ),
            Text(
              name,
              style: GoogleFonts.quicksand(
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 21. PRISM FRACTAL: Multi-angle
  Widget _buildPrismFractalStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.02))
            : (isActive ? Colors.grey[900] : Colors.black),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.white : Colors.white10),
      ),
      child: Stack(
        children: [
          if (isActive)
            Positioned.fill(
              child: CustomPaint(painter: _HologramGridPainter(color: color)),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? iconInfo.iconOn : iconInfo.iconOff,
                  color: isActive ? color : Colors.white24,
                  size: 32.r,
                ),
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.mavenPro(
                    color: isActive ? Colors.white : Colors.white12,
                    letterSpacing: 2.w,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 22. MAGMA CORE: Glowing ripples
  Widget _buildMagmaCoreStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;
    final t = _iconAnimController.value;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.red.withOpacity(0.8)
                  : Colors.red.withOpacity(0.2))
            : (isActive ? Colors.redAccent : Colors.black),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.8),
                  blurRadius: 20 + math.sin(t * 2 * math.pi) * 10,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: Colors.white,
              size: 34.r,
            ),
            Text(
              name,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 23. CYBER BLOOM: Bio-luminescent
  Widget _buildCyberBloomStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.4))
            : (isActive ? color.withOpacity(0.1) : Colors.black),
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        border: Border.all(
          color: isActive ? color : color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? color : color.withOpacity(0.3),
              size: 38.r,
            ),
            Text(
              name,
              style: GoogleFonts.firaSans(
                color: isActive ? Colors.white : Colors.white24,
                fontStyle: FontStyle.italic,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 24. VOID RIFT: Gravity Distortion
  Widget _buildVoidRiftStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.01))
            : Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : Colors.white10,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? Colors.white : Colors.white10,
              size: 32.r,
            ),
            if (isActive)
              SizedBox(
                width: 10.r,
                height: 10.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipOval(
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 25. STARLIGHT ECHO: Twinkling
  Widget _buildStarlightEchoStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.blueGrey.withOpacity(0.4)
                  : Colors.blueGrey.withOpacity(0.1))
            : (isActive ? Colors.blueGrey[900] : Colors.black),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.white : Colors.white12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive ? Colors.white : Colors.white24,
              size: 30.r,
            ),
            Text(
              name,
              style: GoogleFonts.montserrat(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

  // 26. AERO STREAM: Fluid curves
  Widget _buildAeroStreamStyle(
    ThemeData theme,
    String name,
    Color color,
    Color contentColor,
    DeviceIconInfo iconInfo,
    bool blendingEnabled,
  ) {
    final isActive = widget.device.isActive;

    Widget container = Container(
      decoration: BoxDecoration(
        color: blendingEnabled
            ? (isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05))
            : (isActive ? Colors.white : Colors.black),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconInfo.iconOn : iconInfo.iconOff,
              color: isActive
                  ? (blendingEnabled ? Colors.white : Colors.black)
                  : Colors.white24,
              size: 35.r,
            ),
            Text(
              name,
              style: GoogleFonts.josefinSans(
                color: isActive
                    ? (blendingEnabled ? Colors.white : Colors.black)
                    : Colors.white24,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );

    if (blendingEnabled) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: Stack(children: [const SizedBox.shrink(), container]),
        ),
      );
    }
    return RepaintBoundary(child: container);
  }

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
      size: 32.r,
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

class _HologramGridPainter extends CustomPainter {
  final Color color;
  _HologramGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid
    final step = 10.0.w;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Scanline
    final scanPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, color, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuantumDotPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _QuantumDotPainter({required this.color, required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(
      42,
    ); // Seeded for consistancy but animated via time

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;

      final pulse = math.sin((animation.value * 6.28) + i);
      final alpha = (pulse + 1) / 2 * 0.5 + 0.2;

      paint.color = color.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumDotPainter oldDelegate) => true;
}
