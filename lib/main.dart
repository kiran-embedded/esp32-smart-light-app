import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart'; // High Refresh Rate
import 'package:shared_preferences/shared_preferences.dart'; // Added
import 'package:flutter_soloud/flutter_soloud.dart'; // Added
// import 'firebase_options.dart'; // DefaultFirebaseOptions (Missing in workspace)
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/intro/cinematic_splash_screen.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/main/main_screen.dart';
import 'services/persistence_service.dart';

import 'services/sound_service.dart';
import 'services/haptic_service.dart';
import 'providers/switch_provider.dart';
import 'providers/immersive_provider.dart';
import 'providers/animation_provider.dart';
import 'providers/sound_settings_provider.dart'; // Fixed
import 'providers/voice_provider.dart';
import 'widgets/common/restart_widget.dart'; // Added
import 'services/performance_service.dart'; // Added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload critical settings for instant startup response
  final prefs = await SharedPreferences.getInstance();
  final voiceEnabled = prefs.getBool('voice_enabled') ?? true;

  final soundSettings = SoundSettings(
    masterSound: prefs.getBool('master_sound') ?? true,
    appOpeningSound: prefs.getBool('app_opening_sound') ?? true,
    switchSound: prefs.getBool('switch_sound') ?? true,
  );

  // Auto-Tune Performance based on Device Capabilities
  await PerformanceService.optimizeSettings();

  // Initialize Audio
  try {
    await SoLoud.instance.init();
  } catch (e) {
    debugPrint("Audio Init Error: $e");
  }

  // Initialize Firebase
  try {
    // Check if default options are available (commented out due to missing file)
    /*
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    */
    // Fallback: If no options, try init without options (sometimes works on Android if google-services.json is present)
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Init Error (Default): $e");
  }

  // Unlock Maximum High Refresh Rate (Aggressive)
  try {
    await FlutterDisplayMode.setHighRefreshRate(); // Try standard first

    // Aggressive override to find absolute max (e.g., 144Hz vs 120Hz)
    final modes = await FlutterDisplayMode.supported;
    final current = await FlutterDisplayMode.active;

    // Convert to set to remove duplicates, then list to sort
    final sortedModes = modes.toSet().toList()
      ..sort((a, b) => b.refreshRate.compareTo(a.refreshRate));

    if (sortedModes.isNotEmpty) {
      final maxMode = sortedModes.first;
      if (maxMode.refreshRate > current.refreshRate) {
        await FlutterDisplayMode.setPreferredMode(maxMode);
        debugPrint("Forced Max FPS: ${maxMode.refreshRate}Hz");
      }
    }
  } catch (e) {
    debugPrint("Error setting high refresh rate: $e");
  }

  // Industry Level: Immersive Full-Screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pre-cache haptic capabilities for zero-latency feedback
  await HapticService.init();

  // Try to initialize Firebase with persisted config
  try {
    final config = await PersistenceService.getFirebaseConfig();
    if (config != null &&
        config['apiKey'] != null &&
        config['appId'] != null &&
        config['messagingSenderId'] != null &&
        config['projectId'] != null) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey']!,
          appId: config['appId']!,
          messagingSenderId: config['messagingSenderId']!,
          projectId: config['projectId']!,
          databaseURL: config['databaseURL'],
        ),
      );
      debugPrint('Firebase initialized with custom config');
    } else {}
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Load nicknames BEFORE the app starts
  final nicknames = await PersistenceService.getNicknames();

  // Load animation settings BEFORE the app starts
  final animSettings = await PersistenceService.getAnimationSettings();
  final initialLaunch = AppLaunchAnimation.values[animSettings['launch']!];
  final initialUi = UiTransitionAnimation.values[animSettings['ui']!];

  runApp(
    ProviderScope(
      overrides: [
        switchDevicesProvider.overrideWith(
          (ref) => SwitchDevicesNotifier(ref, initialNicknames: nicknames),
        ),
        animationSettingsProvider.overrideWith(
          (ref) => AnimationSettingsNotifier(
            initialLaunch: initialLaunch,
            initialUi: initialUi,
          ),
        ),
        // Fix for startup voice bug: Seed with preloaded value
        voiceEnabledProvider.overrideWith((ref) => VoiceNotifier(voiceEnabled)),
        // Fix for startup sound config
        soundSettingsProvider.overrideWith((ref) {
          final notifier = SoundSettingsNotifier();
          notifier.seed(soundSettings);
          return notifier;
        }),
      ],
      child: const RestartWidget(child: NebulaCoreApp()),
    ),
  );
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
      // Detect when app comes to foreground and wake up connection
      ref.read(firebaseSwitchServiceProvider).preWarmConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Watch immersive mode to apply changes
    ref.watch(immersiveModeProvider);

    // After splash, show destination screen based on auth state
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
      // Composition Engine removed from global scope
      builder: (context, child) => child!,
      home: Listener(
        onPointerDown: (_) {
          // PRE-WARM CONNECTION: Wake up Firebase socket on functionality
          // This reduces the latency for the first write operation.
          ref.read(firebaseSwitchServiceProvider).preWarmConnection();
        },
        child: _buildOpeningAnimation(
          AppLaunchAnimation.iPhoneBlend, // Forced iOS Default
          _showSplash,
          child: _showSplash
              ? CinematicSplashScreen(
                  key: const ValueKey('splash'),
                  onFinished: () {
                    if (mounted) {
                      setState(() {
                        _showSplash = false;
                      });
                    }
                  },
                )
              : KeyedSubtree(
                  key: ValueKey(
                    authState,
                  ), // Key by logic state to ensure proper switching
                  child: destination,
                ),
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
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.butterZoom:
        // True Zoom transition
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.fluidFade:
        // Pure Fade transition for "Fluid" feel
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.zeroLatency:
        // Instant cut
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionBuilder(),
            TargetPlatform.iOS: _NoTransitionBuilder(),
          },
        );
      default:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
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
    // Play sound/haptic when the splash disappears (child changes)
    // Play sound/haptic when the splash disappears (child changes)
    if (!showSplash) {
      // Force startup sound for all animations to ensure it works
      ref.read(soundServiceProvider).playStartup();
      HapticFeedback.lightImpact();
    }

    switch (type) {
      case AppLaunchAnimation.iPhoneBlend:
        // iOS Unlock Style: Icon expands to fill screen
        return AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 1200,
          ), // Slower for noticeability
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(
              begin: 0.5,
              end: 1.0,
            ).animate(animation);
            // Delay the fade slightly so we see the "icon" zooming first
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.1, 1.0),
              ),
            );
            return ScaleTransition(
              scale: scale,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
          child: child,
        );

      case AppLaunchAnimation.cinematicFade:
        // Deep fade
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 2500), // Very slow
          switchInCurve: Curves.easeInExpo,
          switchOutCurve: Curves.easeOutExpo,
          child: child,
        );

      case AppLaunchAnimation.centerBurst:
        // Explosive pop
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          switchInCurve: Curves.elasticOut,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: child,
            );
          },
          child: child,
        );

      case AppLaunchAnimation.bottomSpring:
        // Card Slide Up
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 1100),
          switchInCurve: Curves.elasticOut,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.linearToEaseOut,
                    ),
                  ),
              child: child,
            );
          },
          child: child,
        );

      case AppLaunchAnimation.cyberGlitch:
        // Flash + Scale Snap
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.linear,
          transitionBuilder: (child, animation) {
            final offset =
                Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticIn),
                );

            return SlideTransition(
              position: offset,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: child,
        );

      case AppLaunchAnimation.liquidReveal:
        // Scale + Fade but smoother
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 1600),
          switchInCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              alignment: Alignment.center,
              scale: Tween<double>(begin: 1.2, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: child,
        );

      default:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOut,
          child: child,
        );
    }
  }

  // Simple spring curve for "Apple Feel" internal usage
  static const Curve appleSpring = Cubic(0.25, 0.1, 0.25, 1.0);
}

class SpringCurve extends Curve {
  const SpringCurve();
  @override
  double transformInternal(double t) {
    // Simple spring approximation
    return (1 - (1 - t) * (1 - t)).toDouble();
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
  ) {
    return child;
  }
}
