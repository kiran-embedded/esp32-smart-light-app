import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_refresh_rate_control/flutter_refresh_rate_control.dart'; // High Refresh Rate
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/intro/cinematic_splash_screen.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/main/main_screen.dart';
import 'services/persistence_service.dart';
import 'services/firebase_switch_service.dart';
import 'services/sound_service.dart'; // Added
import 'services/haptic_service.dart'; // Added
import 'providers/switch_provider.dart';
import 'providers/immersive_provider.dart';
import 'providers/animation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Unlock High Refresh Rate (120Hz/240Hz)
  try {
    await FlutterRefreshRateControl().requestHighRefreshRate();
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
      ],
      child: const NebulaCoreApp(),
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
                  key: const ValueKey('destination'),
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
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.fluidFade:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
        );
      case UiTransitionAnimation.zeroLatency:
        return const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
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
