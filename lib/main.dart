import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/intro/cinematic_splash_screen.dart';
import 'widgets/navigation/custom_transitions.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/main/main_screen.dart';
import 'services/persistence_service.dart';
import 'services/scheduler_service.dart';
import 'services/haptic_service.dart';
import 'providers/switch_provider.dart';
import 'services/firebase_switch_service.dart';
import 'providers/immersive_provider.dart';
import 'providers/animation_provider.dart';
import 'providers/sound_settings_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/display_settings_provider.dart'; // Added
import 'widgets/common/restart_widget.dart';
import 'services/performance_service.dart';
import 'services/performance_monitor_service.dart';
import 'core/ui/display_engine_wrapper.dart';
import 'widgets/debug/global_fps_meter.dart';
import 'widgets/debug/developer_test_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload ONLY what is absolutely critical for the UI tree to exist
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase (moved from _initBackgroundSystems to main)
  try {
    // Try custom config first, then default
    final config = await PersistenceService.getFirebaseConfig();
    if (config != null) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey']!,
          appId: config['appId']!,
          messagingSenderId: config['messagingSenderId']!,
          projectId: config['projectId']!,
          databaseURL: config['databaseURL'],
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  // Initialize Background Scheduler
  await SchedulerService.init();

  // Kick off background initializations without awaiting (Zero-Block)
  _initBackgroundSystems(prefs);

  // Industry Level: Immersive Full-Screen (Non-blocking)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Extract initial values for Provider overrides to prevent flash of default state
  final voiceEnabled = prefs.getBool('voice_enabled') ?? true;
  final masterSound = prefs.getBool('master_sound') ?? true;
  final appOpeningSound = prefs.getBool('app_opening_sound') ?? true;
  final switchSound = prefs.getBool('switch_sound') ?? true;

  // Load Animation Settings
  final animLaunchIdx = prefs.getInt('anim_launch_type') ?? 0;
  final animUiIdx = prefs.getInt('anim_ui_type') ?? 0;

  final soundSettings = SoundSettings(
    masterSound: masterSound,
    appOpeningSound: appOpeningSound,
    switchSound: switchSound,
  );

  runApp(
    RestartWidget(
      child: ProviderScope(
        overrides: [
          // Pre-inject essential settings to ensure zero-jank first frame
          voiceEnabledProvider.overrideWith(
            (ref) => VoiceNotifier(voiceEnabled),
          ),
          soundSettingsProvider.overrideWith((ref) {
            final notifier = SoundSettingsNotifier();
            notifier.seed(soundSettings);
            return notifier;
          }),
          animationSettingsProvider.overrideWith((ref) {
            return AnimationSettingsNotifier(
              initialLaunch: AppLaunchAnimation.values[animLaunchIdx],
              initialUi: UiTransitionAnimation.values[animUiIdx],
            );
          }),
        ],
        child: const NebulaCoreApp(),
      ),
    ),
  );
}

/// Handle secondary initializations in background to ensure instant Splash visibility
Future<void> _initBackgroundSystems(SharedPreferences prefs) async {
  // 1. High Refresh Rate (Non-blocking high-frequency unlock)
  FlutterDisplayMode.setHighRefreshRate().catchError(
    (e) => debugPrint("HighFPS Error: $e"),
  );

  // 2. Audio Engine (Initializes in background)
  SoLoud.instance.init().catchError((e) => debugPrint("Audio Init Error: $e"));

  // 3. Firebase & Connection Tuning
  try {
    // Try custom config first, then default
    final config = await PersistenceService.getFirebaseConfig();
    if (config != null) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey']!,
          appId: config['appId']!,
          messagingSenderId: config['messagingSenderId']!,
          projectId: config['projectId']!,
          databaseURL: config['databaseURL'],
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    FirebaseSwitchService().optimizeConnection(true);
  } catch (e) {
    debugPrint("Firebase Background Init Error: $e");
  }

  // 4. Haptics, Performance & Pre-caching
  HapticService.init();
  PerformanceService.optimizeSettings();
  PersistenceService.getNicknames();
}

class NebulaCoreApp extends ConsumerStatefulWidget {
  const NebulaCoreApp({super.key});

  @override
  ConsumerState<NebulaCoreApp> createState() => _NebulaCoreAppState();
}

class _NebulaCoreAppState extends ConsumerState<NebulaCoreApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(firebaseSwitchServiceProvider).preWarmConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    ref.watch(immersiveModeProvider);

    Widget destination;
    switch (authState) {
      case AuthState.authenticated:
        destination = const MainScreen();
        break;
      case AuthState.unconfigured:
        destination = const FirebaseSetupScreen();
        break;
      default:
        destination = const LoginScreen();
    }

    final animSettings = ref.watch(animationSettingsProvider);

    return MaterialApp(
      title: 'NEBULA CORE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeMode).copyWith(
        pageTransitionsTheme: _buildPageTransitions(animSettings.uiType),
      ),
      builder: (context, child) {
        // Global Response Init with identifying scale
        // We use pillScale as the proxy for "Display Size"
        final display = ref.watch(displaySettingsProvider);
        Responsive.init(context, scaleFactor: display.pillScale);

        return Consumer(
          builder: (context, ref, _) {
            final stats = ref.watch(performanceStatsProvider);
            debugPrint('ROOT_LOG: Console Visible: ${stats.consoleVisible}');
            return Stack(
              children: [
                if (child != null) child,
                const GlobalFpsMeter(),
                if (stats.consoleVisible) const DeveloperTestOverlay(),
              ],
            );
          },
        );
      },
      home: Listener(
        onPointerDown: (_) =>
            ref.read(firebaseSwitchServiceProvider).preWarmConnection(),
        child: _buildOpeningAnimation(
          animSettings.launchType,
          _showSplash,
          child: _showSplash
              ? RepaintBoundary(
                  child: CinematicSplashScreen(
                    key: const ValueKey('splash'),
                    onFinished: () {
                      if (mounted) {
                        setState(() {
                          _showSplash = false;
                        });
                      }
                    },
                  ),
                )
              : KeyedSubtree(key: ValueKey(authState), child: destination),
        ),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
    );
  }

  PageTransitionsTheme _buildPageTransitions(UiTransitionAnimation type) {
    switch (type) {
      case UiTransitionAnimation.iOSSlide:
      case UiTransitionAnimation.iosExactSlide:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: IOSTransitionBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.magneticPull:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: MagneticPullTransitionBuilder(),
            TargetPlatform.iOS: MagneticPullTransitionBuilder(),
          },
        );
      case UiTransitionAnimation.gravityDrop:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: GravityDropTransitionBuilder(),
            TargetPlatform.iOS: GravityDropTransitionBuilder(),
          },
        );
      case UiTransitionAnimation.butterZoom:
        return PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const NebulaZoomTransitionBuilder(),
            TargetPlatform.iOS: const NebulaZoomTransitionBuilder(),
          },
        );
      case UiTransitionAnimation.fluidFade:
        return PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const NebulaFadeUpwardsTransitionBuilder(),
            TargetPlatform.iOS: const NebulaFadeUpwardsTransitionBuilder(),
          },
        );
      case UiTransitionAnimation.zeroLatency:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionBuilder(),
            TargetPlatform.iOS: _NoTransitionBuilder(),
          },
        );
      default:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: IOSTransitionBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );
    }
  }

  Widget _buildOpeningAnimation(
    AppLaunchAnimation type,
    bool showSplash, {
    required Widget child,
  }) {
    // Ensuring haptics and sound only trigger once per state change limits handled by logic outside this build
    // But we trigger feedback on complete entry

    // Unified Transition Engine
    // We strictly differentiate between the Splash and the App using Keys.
    return AnimatedSwitcher(
      duration: _getTransitionDuration(type),
      switchInCurve: _getInCurve(type),
      switchOutCurve: _getOutCurve(type),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isSplash = child.key == const ValueKey('splash');

        // ALWAYS Fade the Splash out gracefully. Never jank it.
        if (isSplash) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              // Fix: Subtle scale from 1.05 down to 1.0 as it fades out (1->0)
              // Tween(begin: 1.05, end: 1.0).animate(animation)
              // At 1.0 (start of exit): 1.05
              // At 0.0 (end of exit): 1.0
              // This gives a settling effect "Zoom Out"
              scale: Tween<double>(begin: 1.08, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        }

        // Apply distinct physics for the Incoming App
        return _buildAppTransition(type, child, animation);
      },
      child: child,
    );
  }

  Duration _getTransitionDuration(AppLaunchAnimation type) {
    switch (type) {
      case AppLaunchAnimation.galaxySpiral:
        return const Duration(milliseconds: 1400); // Slower, more majestic
      case AppLaunchAnimation.cinematicFade:
        return const Duration(milliseconds: 1000);
      case AppLaunchAnimation.cyberGlitch:
        return const Duration(milliseconds: 700);
      case AppLaunchAnimation.bladeRunner:
        return const Duration(milliseconds: 500);
      case AppLaunchAnimation.bottomSpring:
        return const Duration(milliseconds: 900);
      default:
        return const Duration(milliseconds: 800);
    }
  }

  Curve _getInCurve(AppLaunchAnimation type) {
    switch (type) {
      case AppLaunchAnimation.galaxySpiral:
        return Curves.easeInOutCirc; // More dramatic ease
      case AppLaunchAnimation.bottomSpring:
        return Curves.elasticOut; // Keep elastic
      case AppLaunchAnimation.fluidWave:
        return Curves.slowMiddle; // Viscous feel
      case AppLaunchAnimation.bladeRunner:
        return Curves.fastLinearToSlowEaseIn; // Snap and glide
      default:
        return Curves.easeOutQuart;
    }
  }

  Curve _getOutCurve(AppLaunchAnimation type) =>
      Curves.linear; // Splash always linear out for consistency

  Widget _buildAppTransition(
    AppLaunchAnimation type,
    Widget child,
    Animation<double> animation,
  ) {
    switch (type) {
      // 1. LIQUID / FLUID (Smooth scaling from center)
      case AppLaunchAnimation.fluidWave:
      case AppLaunchAnimation.liquidReveal:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastLinearToSlowEaseIn,
              ),
            ),
            child: child,
          ),
        );

      // 2. CINEMATIC / ENERGY (Complex Physics)
      case AppLaunchAnimation.galaxySpiral:
        return RotationTransition(
          turns: Tween<double>(begin: 0.8, end: 1.0).animate(
            // Subtle twist entry
            CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );

      case AppLaunchAnimation.quantumTunnel:
        return ScaleTransition(
          scale: Tween<double>(begin: 2.0, end: 1.0).animate(
            // Zoom IN from void
            CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );

      case AppLaunchAnimation.hologramRise:
      case AppLaunchAnimation.neonPulse:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ), // Pulse/Pop
              ),
              child: child,
            ),
          ),
        );

      case AppLaunchAnimation.cinematicFade:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.1, end: 1.0).animate(
              // Gentle push back
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );

      // 3. FAST / BLADE RUNNER (Sharp slide up)
      case AppLaunchAnimation.bladeRunner:
      case AppLaunchAnimation.bottomSpring:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );

      // 4. GLITCH / CYBER (Holographic flicker entry)
      case AppLaunchAnimation.cyberGlitch:
      case AppLaunchAnimation.pixelReveal:
        return AnimatedBuilder(
          animation: animation,
          builder: (context, c) {
            // Simulated interference
            final val = animation.value;
            final offset = (val < 0.8) ? (0.02 * (1 - val)) : 0.0;
            return Transform.translate(
              offset: Offset(offset * 100, 0),
              child: Opacity(opacity: val.clamp(0.0, 1.0), child: c),
            );
          },
          child: child,
        );

      // 5. IPHONE / DEFAULT (Standard smooth fade-scale)
      default:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
    }
  }
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
