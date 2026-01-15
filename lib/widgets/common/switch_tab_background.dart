import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/switch_background_provider.dart';
import '../../providers/switch_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/theme_provider.dart';

class SwitchTabBackground extends ConsumerWidget {
  final Widget child;

  const SwitchTabBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(switchBackgroundProvider);
    final devices = ref.watch(switchDevicesProvider);
    final performanceMode = ref.watch(performanceProvider);
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);

    // High Performance optimization: Disable animated backgrounds
    if (performanceMode) {
      return ColoredBox(color: theme.scaffoldBackgroundColor);
    }

    // Use theme colors for coherent feel
    Color primaryColor = theme.colorScheme.primary;
    Color secondaryColor = theme.colorScheme.secondary;

    // Blend with active switches if any
    final activeSwitches = devices.where((s) => s.isActive).toList();
    if (activeSwitches.isNotEmpty) {
      // Generate color hash from active switch ID for consistency
      final s = activeSwitches.first;
      final hash = s.id.hashCode;
      final switchColor = HSVColor.fromAHSV(
        1.0,
        (hash.abs() % 360).toDouble(),
        0.7,
        0.8,
      ).toColor();

      // Blend theme color with switch color (70% theme, 30% switch)
      primaryColor = Color.lerp(theme.colorScheme.primary, switchColor, 0.3)!;

      if (activeSwitches.length > 1) {
        final s2 = activeSwitches[1];
        final hash2 = s2.id.hashCode;
        final switchColor2 = HSVColor.fromAHSV(
          1.0,
          (hash2.abs() % 360).toDouble(),
          0.7,
          0.8,
        ).toColor();
        secondaryColor = Color.lerp(
          theme.colorScheme.secondary,
          switchColor2,
          0.3,
        )!;
      } else {
        // Use complementary color from theme
        final hsv = HSVColor.fromColor(primaryColor);
        secondaryColor = hsv.withHue((hsv.hue + 60) % 360).toColor();
      }
    }

    return Stack(
      children: [
        // Background Layer
        Positioned.fill(
          child: _buildBackground(style, primaryColor, secondaryColor),
        ),
        // Blending Layer - Theme-aware overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.scaffoldBackgroundColor.withOpacity(0.4),
                  theme.scaffoldBackgroundColor.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        // Content Layer
        child,
      ],
    );
  }

  Widget _buildBackground(
    SwitchBackgroundType style,
    Color primary,
    Color secondary,
  ) {
    // Wrap in RepaintBoundary to isolate animation painting from the rest of the UI
    return RepaintBoundary(
      child: _getBackgroundWidget(style, primary, secondary),
    );
  }

  Widget _getBackgroundWidget(
    SwitchBackgroundType style,
    Color primary,
    Color secondary,
  ) {
    switch (style) {
      case SwitchBackgroundType.defaultBlack:
        return const ColoredBox(color: Colors.black);
      case SwitchBackgroundType.neonBorder:
        return _AnimatedPainter(
          painterType: _PainterType.neonBorder,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.danceFloor:
        return _AnimatedPainter(
          painterType: _PainterType.danceFloor,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.cosmicNebula:
        return _AnimatedPainter(
          painterType: _PainterType.cosmicNebula,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.cyberGrid:
        return _AnimatedPainter(
          painterType: _PainterType.cyberGrid,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.liquidPlasma:
        return _AnimatedPainter(
          painterType: _PainterType.liquidPlasma,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.digitalRain:
        return _AnimatedPainter(
          painterType: _PainterType.digitalRain,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.retroSynth:
        return _AnimatedPainter(
          painterType: _PainterType.retroSynth,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.bokehLights:
        return _AnimatedPainter(
          painterType: _PainterType.bokehLights,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.auroraBorealis:
        return _AnimatedPainter(
          painterType: _PainterType.auroraBorealis,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.circuitBoard:
        return _AnimatedPainter(
          painterType: _PainterType.circuitBoard,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.fireEmbers:
        return _AnimatedPainter(
          painterType: _PainterType.fireEmbers,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.deepOcean:
        return _AnimatedPainter(
          painterType: _PainterType.deepOcean,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.glassPrism:
        return _AnimatedPainter(
          painterType: _PainterType.glassPrism,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.starField:
        return _AnimatedPainter(
          painterType: _PainterType.starField,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.hexHive:
        return _AnimatedPainter(
          painterType: _PainterType.hexHive,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.neuralNodes:
        return _AnimatedPainter(
          painterType: _PainterType.neuralNodes,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.dataStream:
        return _AnimatedPainter(
          painterType: _PainterType.dataStream,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.whiteFlash:
        return const ColoredBox(color: Colors.white);
      case SwitchBackgroundType.solarFlare:
        return _AnimatedPainter(
          painterType: _PainterType.solarFlare,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.electricTundra:
        return _AnimatedPainter(
          painterType: _PainterType.electricTundra,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.nanoCatalyst:
        return _AnimatedPainter(
          painterType: _PainterType.nanoCatalyst,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.phantomVelvet:
        return _AnimatedPainter(
          painterType: _PainterType.phantomVelvet,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.prismFractal:
        return _AnimatedPainter(
          painterType: _PainterType.prismFractal,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.magmaCore:
        return _AnimatedPainter(
          painterType: _PainterType.magmaCore,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.cyberBloom:
        return _AnimatedPainter(
          painterType: _PainterType.cyberBloom,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.voidRift:
        return _AnimatedPainter(
          painterType: _PainterType.voidRift,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.starlightEcho:
        return _AnimatedPainter(
          painterType: _PainterType.starlightEcho,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.aeroStream:
        return _AnimatedPainter(
          painterType: _PainterType.aeroStream,
          primary: primary,
          secondary: secondary,
        );
      case SwitchBackgroundType.nebulaDynamic:
        return _AnimatedPainter(
          painterType: _PainterType.nebulaSpace,
          primary: primary,
          secondary: secondary,
        );
    }
  }
}

enum _PainterType {
  neonBorder,
  danceFloor,
  cosmicNebula,
  cyberGrid,
  liquidPlasma,
  digitalRain,
  retroSynth,
  bokehLights,
  auroraBorealis,
  circuitBoard,
  fireEmbers,
  deepOcean,
  glassPrism,
  starField,
  hexHive,
  neuralNodes,
  dataStream,
  solarFlare,
  electricTundra,
  nanoCatalyst,
  phantomVelvet,
  prismFractal,
  magmaCore,
  cyberBloom,
  voidRift,
  starlightEcho,
  aeroStream,
  nebulaSpace,
}

class _AnimatedPainter extends StatefulWidget {
  final _PainterType painterType;
  final Color primary;
  final Color secondary;

  const _AnimatedPainter({
    required this.painterType,
    this.primary = Colors.cyanAccent,
    this.secondary = Colors.purpleAccent,
  });

  @override
  State<_AnimatedPainter> createState() => _AnimatedPainterState();
}

class _AnimatedPainterState extends State<_AnimatedPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _getPainter(
        widget.painterType,
        _controller,
        widget.primary,
        widget.secondary,
      ),
      size: Size.infinite,
      isComplex: true, // Hint to engine to cache if possible
      willChange: true, // Hint that it changes every frame
    );
  }

  CustomPainter _getPainter(
    _PainterType type,
    AnimationController controller,
    Color primary,
    Color secondary,
  ) {
    switch (type) {
      case _PainterType.neonBorder:
        return _NeonBorderPainter(controller, primary, secondary);
      case _PainterType.danceFloor:
        return _DanceFloorPainter(controller, primary, secondary);
      case _PainterType.cosmicNebula:
        return _CosmicNebulaPainter(controller, primary, secondary);
      case _PainterType.cyberGrid:
        return _CyberGridPainter(controller, primary, secondary);
      case _PainterType.liquidPlasma:
        return _LiquidPlasmaPainter(controller, primary, secondary);
      case _PainterType.digitalRain:
        return _DigitalRainPainter(controller, primary, secondary);
      case _PainterType.retroSynth:
        return _RetroSynthPainter(controller, primary, secondary);
      case _PainterType.bokehLights:
        return _BokehLightsPainter(controller, primary, secondary);
      case _PainterType.auroraBorealis:
        return _AuroraPainter(controller, primary, secondary);
      case _PainterType.circuitBoard:
        return _CircuitBoardPainter(controller, primary, secondary);
      case _PainterType.fireEmbers:
        return _FireEmbersPainter(controller, primary, secondary);
      case _PainterType.deepOcean:
        return _DeepOceanPainter(controller, primary, secondary);
      case _PainterType.glassPrism:
        return _GlassPrismPainter(controller, primary, secondary);
      case _PainterType.starField:
        return _StarFieldPainter(controller, primary, secondary);
      case _PainterType.hexHive:
        return _HexHivePainter(controller, primary, secondary);
      case _PainterType.neuralNodes:
        return _NeuralNodesPainter(controller, primary, secondary);
      case _PainterType.dataStream:
        return _DataStreamPainter(controller, primary, secondary);
      case _PainterType.solarFlare:
        return _SolarFlarePainter(controller, primary, secondary);
      case _PainterType.electricTundra:
        return _ElectricTundraPainter(controller, primary, secondary);
      case _PainterType.nanoCatalyst:
        return _NanoCatalystPainter(controller, primary, secondary);
      case _PainterType.phantomVelvet:
        return _PhantomVelvetPainter(controller, primary, secondary);
      case _PainterType.prismFractal:
        return _PrismFractalPainter(controller, primary, secondary);
      case _PainterType.magmaCore:
        return _MagmaCorePainter(controller, primary, secondary);
      case _PainterType.cyberBloom:
        return _CyberBloomPainter(controller, primary, secondary);
      case _PainterType.voidRift:
        return _VoidRiftPainter(controller, primary, secondary);
      case _PainterType.starlightEcho:
        return _StarlightEchoPainter(controller, primary, secondary);
      case _PainterType.aeroStream:
        return _AeroStreamPainter(controller, primary, secondary);
      case _PainterType.nebulaSpace:
        return _NebulaSpacePainter(controller);
    }
  }
}

// --- PAINTERS ---

class _NeonBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;

  _NeonBorderPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          20 // Thicker for softer glow
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      ); // Reduced from 10

    final colors = [
      primary.withOpacity(0.6), // Reduced opacity
      secondary.withOpacity(0.6),
      Color.lerp(primary, secondary, 0.5)!.withOpacity(0.3),
      primary.withOpacity(0.6),
    ];
    final stops = [0.0, 0.33, 0.66, 1.0];

    paint.shader = SweepGradient(
      colors: colors,
      stops: stops,
      transform: GradientRotation(animation.value * 2 * pi),
    ).createShader(rect);

    canvas.drawRect(rect.deflate(10), paint);

    // Inner glow
    paint.strokeWidth = 4;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    // paint.maskFilter = null; // Removed sharp inner line
    canvas.drawRect(rect.deflate(10), paint);
  }

  @override
  bool shouldRepaint(covariant _NeonBorderPainter oldDelegate) => true;
}

class _DanceFloorPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _DanceFloorPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final tileSize = 60.0;
    final cols = (size.width / tileSize).ceil();
    final rows = (size.height / tileSize).ceil();

    // Performance: Avoid HSL conversion in loop.
    // Use pre-defined colors or simpler interpolation.
    final t = animation.value;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        // Pseudo-random pulsing based on time and position
        final noise = sin(x * 0.5 + t * 10) * cos(y * 0.5 + t * 5);
        if (noise > 0.7) {
          // Reduced density for perf
          final color = Color.lerp(
            primary,
            secondary,
            (x + y) / (cols + rows),
          )!;

          final paint = Paint()..color = color;
          // Removing blur mask inside loop greatly improves FPS
          // paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

          canvas.drawRect(
            Rect.fromLTWH(
              x * tileSize,
              y * tileSize,
              tileSize - 2,
              tileSize - 2,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DanceFloorPainter oldDelegate) => true;
}

class _CosmicNebulaPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _CosmicNebulaPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF050010), BlendMode.src);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        15,
      ); // Reduced from 30
    final points = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.5),
    ];
    final colors = [
      primary.withOpacity(0.3),
      secondary.withOpacity(0.3),
      Color.lerp(primary, secondary, 0.5)!.withOpacity(0.3),
    ];

    for (int i = 0; i < points.length; i++) {
      final t = animation.value * 2 * pi + (i * 2);
      final offset = Offset(sin(t) * 50, cos(t) * 30);
      paint.color = colors[i];
      canvas.drawCircle(points[i] + offset, 120, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CyberGridPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _CyberGridPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black,
          secondary.withOpacity(0.2), // Dynamic secondary
          Colors.black,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final paint = Paint()
      ..color = primary
          .withOpacity(0.3) // Dynamic primary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final spacing = 40.0;
    final offset = animation.value * spacing;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset - spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LiquidPlasmaPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _LiquidPlasmaPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final t = animation.value * 2 * pi;
    for (int i = 0; i < 8; i++) {
      // Reduced from 20
      final x = size.width / 2 + sin(t * (i + 1) * 0.1) * size.width * 0.4;
      final y = size.height / 2 + cos(t * (i + 1) * 0.13) * size.height * 0.4;
      paint.color = Color.lerp(primary, secondary, i / 8)!.withOpacity(0.5);
      canvas.drawCircle(Offset(x, y), 60 + sin(t) * 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DigitalRainPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _DigitalRainPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final paint = Paint()
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 2;
    // Optimized: Draw lines/dots instead of TextPainter layout
    final random = Random(123);
    final cols = (size.width / 15).floor();

    for (int i = 0; i < cols; i++) {
      final speed = random.nextDouble() * 5 + 2;
      final dropY =
          (animation.value * 500 * speed + random.nextDouble() * size.height) %
          (size.height + 100);

      // Draw trail as series of rects
      for (int j = 0; j < 8; j++) {
        final opacity = 1.0 - (j * 0.12);
        if (opacity <= 0) continue;

        paint.color = primary.withOpacity(opacity);
        // Draw a "character" representation (small rects/lines)
        if (random.nextBool()) {
          canvas.drawLine(
            Offset(i * 15.0, dropY - j * 15),
            Offset(i * 15.0 + 8, dropY - j * 15),
            paint,
          );
        } else {
          canvas.drawLine(
            Offset(i * 15.0 + 4, dropY - j * 15),
            Offset(i * 15.0 + 4, dropY - j * 15 + 8),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RetroSynthPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _RetroSynthPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Sun
    final sunGradient = LinearGradient(
      colors: [primary, secondary],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height / 2));

    final sunPaint = Paint()..shader = sunGradient;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 80, sunPaint);

    // Grid
    final gridPaint = Paint()
      ..color = secondary.withOpacity(0.5)
      ..strokeWidth = 1;
    final horizonY = size.height * 0.5;

    // Horizontal moving lines (Perspective)
    final t = animation.value;
    for (double z = 0; z < 1.0; z += 0.05) {
      // simple perspective hack
      double y = horizonY + (z * size.height / 2);
      double modY = y + (t * 20) % 20; // Move forward
      canvas.drawLine(Offset(0, modY), Offset(size.width, modY), gridPaint);
    }

    // Vertical fan lines
    for (double x = -size.width; x < size.width * 2; x += 40) {
      canvas.drawLine(
        Offset(size.width / 2, horizonY),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BokehLightsPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _BokehLightsPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(0xFF101010), BlendMode.src);
    final random = Random(5);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final yBase = random.nextDouble() * size.height;
      final speed = random.nextDouble() + 0.2;
      final y =
          (yBase - animation.value * size.height * speed) % (size.height + 50);
      final r = random.nextDouble() * 30 + 10;

      paint.color = (random.nextBool() ? primary : secondary).withOpacity(
        random.nextDouble() * 0.3,
      );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _AuroraPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final paint = Paint()
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        15,
      ); // Reduced from 30
    final t = animation.value * 2 * pi;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      path.moveTo(0, size.height * 0.4 + i * 50);
      for (double x = 0; x <= size.width; x += 10) {
        path.lineTo(x, size.height * 0.4 + i * 50 + sin(x * 0.01 + t + i) * 50);
      }
      paint.color =
          (i == 0
                  ? primary
                  : (i == 1 ? secondary : Color.lerp(primary, secondary, 0.5)!))
              .withOpacity(0.4);
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CircuitBoardPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _CircuitBoardPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(0xFF001000), BlendMode.src);
    final paint = Paint()
      ..color = primary.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final random = Random(99);

    // Draw static tracks
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + (random.nextBool() ? 100 : -100), y),
        paint,
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + (random.nextBool() ? 100 : -100)),
        paint,
      );
      canvas.drawCircle(Offset(x, y), 4, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }

    // Pulse
    final pulsePaint = Paint()
      ..color =
          secondary // Dynamic secondary
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4);
    final pulsePos = (animation.value * size.height * 2) % size.height;
    // Just a simple scanline for effect
    canvas.drawLine(
      Offset(0, pulsePos),
      Offset(size.width, pulsePos),
      pulsePaint..color = secondary.withOpacity(0.1),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FireEmbersPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _FireEmbersPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(0xFF100000), BlendMode.src);
    final random = Random(44);
    final paint = Paint();

    for (int i = 0; i < 50; i++) {
      final xBase = random.nextDouble() * size.width;
      final speed = random.nextDouble() * 2 + 1;
      final y =
          (size.height -
          (animation.value * size.height * speed +
                  random.nextDouble() * size.height) %
              size.height);

      // Wiggle
      final x = xBase + sin(y * 0.05) * 10;

      paint.color = primary.withOpacity((y / size.height) * 0.8);
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 3 + 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DeepOceanPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _DeepOceanPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF001030), Color(0xFF000510)], // Keep Deep Blue base
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Caustics lines
    final paint = Paint()
      ..color = primary
          .withOpacity(0.1) // Dynamic primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final t = animation.value * pi * 2;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      path.moveTo(0, size.height / 10 * i);
      for (double x = 0; x < size.width; x += 20) {
        path.lineTo(x, size.height / 10 * i + sin(x * 0.02 + t + i) * 20);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlassPrismPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _GlassPrismPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(0xFFEEF2F5), BlendMode.src); // Light bg
    final paint = Paint()..style = PaintingStyle.fill;
    final t = animation.value * 2 * pi;

    // Moving triangles
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 3; i++) {
      final offset = Offset(cos(t + i * 2) * 50, sin(t + i * 2) * 50);
      final path = Path();
      final p = center + offset;
      path.moveTo(p.dx, p.dy - 100);
      path.lineTo(p.dx + 86, p.dy + 50);
      path.lineTo(p.dx - 86, p.dy + 50);
      path.close();

      paint.color =
          (i == 0
                  ? primary
                  : (i == 1 ? secondary : Color.lerp(primary, secondary, 0.5)!))
              .withOpacity(0.2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StarFieldPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _StarFieldPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final paint = Paint()..color = Colors.white;
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(1);

    for (int i = 0; i < 100; i++) {
      // Simulate 3D Z movement
      double z = (random.nextDouble() * 1000 - animation.value * 1000) % 1000;
      if (z < 0) z += 1000;
      if (z < 1) z = 1;

      final x = (random.nextDouble() - 0.5) * size.width * 2;
      final y = (random.nextDouble() - 0.5) * size.height * 2;

      final sx = center.dx + (x / z) * 100;
      final sy = center.dy + (y / z) * 100;

      final r = (1 - z / 1000) * 3;
      // Tint stars slightly with primary
      paint.color = primary.withOpacity(1 - z / 1000);

      if (sx > 0 && sx < size.width && sy > 0 && sy < size.height) {
        canvas.drawCircle(Offset(sx, sy), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HexHivePainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _HexHivePainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Color(0xFF0A0A0A), BlendMode.src);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = primary.withOpacity(0.3); // Dynamic primary
    final r = 30.0;
    final h = r * sqrt(3);

    final cols = (size.width / (r * 1.5)).ceil();
    final rows = (size.height / h).ceil();

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final cx = x * r * 1.5;
        final cy = y * h + (x % 2 == 1 ? h / 2 : 0);

        // Pulse
        final dist = sqrt(
          pow(cx - size.width / 2, 2) + pow(cy - size.height / 2, 2),
        );
        final wave = sin(dist * 0.01 - animation.value * 10);

        paint.color = secondary.withOpacity(
          // Dynamic secondary
          (wave * 0.3 + 0.3).clamp(0.1, 0.6),
        );
        paint.strokeWidth = wave > 0.8 ? 2 : 1;

        _drawHex(canvas, Offset(cx, cy), r, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NeuralNodesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _NeuralNodesPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF00050A), BlendMode.src);
    final points = List.generate(20, (i) {
      final t = animation.value * 2 * pi + i;
      return Offset(
        size.width * 0.5 + cos(t * 0.5) * size.width * 0.4,
        size.height * 0.5 + sin(t * 0.7) * size.height * 0.4,
      );
    });

    final paint = Paint()
      ..color = primary.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw connections
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < 200) {
          paint.color = primary.withOpacity((1 - dist / 200) * 0.2);
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }

    // Draw nodes
    for (var p in points) {
      canvas.drawCircle(p, 3, Paint()..color = primary);
      // Outer glow
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = primary.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DataStreamPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _DataStreamPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final random = Random(7);
    final cols = (size.width / 20).floor();
    final paint = Paint()..color = primary.withOpacity(0.5);

    for (int i = 0; i < cols; i++) {
      final speed = random.nextDouble() * 3 + 1;
      final yBase = (animation.value * 1000 * speed) % (size.height + 200);

      for (int j = 0; j < 15; j++) {
        final y = yBase - (j * 15);
        if (y < 0 || y > size.height) continue;

        final opacity = 1.0 - (j / 15);
        paint.color = primary.withOpacity(opacity * 0.6);

        // Draw binary-ish blocks
        final isOne = random.nextBool();
        if (isOne) {
          canvas.drawRect(Rect.fromLTWH(i * 20.0 + 5, y, 4, 10), paint);
        } else {
          canvas.drawCircle(Offset(i * 20.0 + 7, y + 5), 3, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SolarFlarePainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _SolarFlarePainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF1A0500), BlendMode.src);
    final center = Offset(size.width / 2, size.height / 2);
    final t = animation.value * 2 * pi;

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    for (int i = 0; i < 8; i++) {
      final angle = t + (i * pi / 4);
      final offset = Offset(cos(angle), sin(angle)) * (50 + sin(t * 2) * 20);
      paint.color = primary.withOpacity(0.3);
      canvas.drawCircle(center + offset, 80 + sin(t + i) * 30, paint);
    }

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, primary, secondary, Colors.transparent],
        stops: const [0.0, 0.2, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 100));
    canvas.drawCircle(center, 100 + sin(t) * 10, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ElectricTundraPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _ElectricTundraPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF000A1A), BlendMode.src);
    final paint = Paint()
      ..color = primary.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final random = Random(42);
    for (int i = 0; i < 15; i++) {
      final path = Path();
      double x = random.nextDouble() * size.width;
      double y = 0;
      path.moveTo(x, y);
      for (int j = 0; j < 10; j++) {
        x += (random.nextDouble() - 0.5) * 40;
        y += size.height / 10;
        path.lineTo(x, y);
      }
      final pulse = (sin(animation.value * 10 + i) + 1) / 2;
      paint.color = primary.withOpacity(pulse * 0.3);
      paint.strokeWidth = 1 + pulse * 2;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NanoCatalystPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _NanoCatalystPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF0A0A0A), BlendMode.src);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = primary.withOpacity(0.1);

    final spacing = 50.0;
    final t = animation.value * 2 * pi;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final d = Offset(x - size.width / 2, y - size.height / 2).distance;
        final s = (sin(d * 0.02 - t) + 1) / 2;
        if (s > 0.8) {
          paint.color = Color.lerp(primary, secondary, s)!.withOpacity(0.2);
          _drawHex(canvas, Offset(x, y), 15 * s, paint);
        }
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhantomVelvetPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _PhantomVelvetPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF05000A), BlendMode.src);
    final t = animation.value * 2 * pi;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    for (int i = 0; i < 5; i++) {
      final x = size.width / 2 + sin(t * 0.3 + i) * size.width * 0.3;
      final y = size.height / 2 + cos(t * 0.2 + i * 2) * size.height * 0.3;
      paint.color = secondary.withOpacity(0.15);
      canvas.drawCircle(Offset(x, y), 150 + sin(t + i) * 50, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PrismFractalPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _PrismFractalPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF000000), BlendMode.src);
    final t = animation.value * 2 * pi;
    final paint = Paint()..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = t + (i * pi / 6);
      final x1 = size.width / 2;
      final y1 = size.height / 2;
      final x2 = x1 + cos(angle) * size.width;
      final y2 = y1 + sin(angle) * size.height;

      paint.shader = LinearGradient(
        colors: [
          primary.withOpacity(0),
          secondary.withOpacity(0.4),
          primary.withOpacity(0),
        ],
      ).createShader(Rect.fromPoints(Offset(x1, y1), Offset(x2, y2)));

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MagmaCorePainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _MagmaCorePainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF100500), BlendMode.src);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final t = animation.value * 2 * pi;

    final random = Random(66);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + t * 50) % size.height;
      paint.color = primary.withOpacity(0.3);
      canvas.drawCircle(Offset(x, y), 30 + sin(t + i) * 10, paint);
    }

    final lavaPaint = Paint()
      ..shader = LinearGradient(
        colors: [primary, secondary, primary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, (sin(t) + 1) / 2, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      lavaPaint..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CyberBloomPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _CyberBloomPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF000500), BlendMode.src);
    final t = animation.value * 2 * pi;
    final paint = Paint()
      ..color = primary.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final startX = size.width / 6 * i;
      path.moveTo(startX, size.height);
      for (double y = size.height; y > 0; y -= 20) {
        path.lineTo(startX + sin(y * 0.05 + t + i) * 30, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _VoidRiftPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _VoidRiftPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF000000), BlendMode.src);
    final center = Offset(size.width / 2, size.height / 2);
    final t = animation.value * 2 * pi;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final r = (i * 20.0 + t * 20) % 400;
      paint.color = primary.withOpacity((1 - r / 400) * 0.4);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StarlightEchoPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _StarlightEchoPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF000005), BlendMode.src);
    final t = animation.value;
    final random = Random(77);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = (sin(t * 5 + i) + 1) / 2;
      final paint = Paint()..color = Colors.white.withOpacity(opacity * 0.8);
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AeroStreamPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primary;
  final Color secondary;
  _AeroStreamPainter(this.animation, this.primary, this.secondary)
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFF0A1A2A), BlendMode.src);
    final t = animation.value * 2 * pi;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 40
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    for (int i = 0; i < 4; i++) {
      final path = Path();
      path.moveTo(0, size.height * 0.2 * i);
      for (double x = 0; x < size.width; x += 50) {
        path.lineTo(x, size.height * 0.2 * i + sin(x * 0.005 + t + i) * 100);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NebulaSpacePainter extends CustomPainter {
  final Animation<double> animation;
  _NebulaSpacePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0E21), // Navy
        const Color(0xFF1A0B2E), // Purple
        Colors.black, // Black
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = gradient);

    // Add subtle animated glow/nebula spots
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final t = animation.value * 2 * pi;

    // Spot 1: Electric Cyan
    final spot1 = Offset(
      size.width * (0.5 + 0.2 * sin(t * 0.5)),
      size.height * (0.3 + 0.1 * cos(t * 0.3)),
    );
    canvas.drawCircle(spot1, 150, paint..color = const Color(0x3300FAFF));

    // Spot 2: Soft Violet
    final spot2 = Offset(
      size.width * (0.2 + 0.1 * cos(t * 0.4)),
      size.height * (0.7 + 0.2 * sin(t * 0.6)),
    );
    canvas.drawCircle(spot2, 200, paint..color = const Color(0x22BB86FC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
