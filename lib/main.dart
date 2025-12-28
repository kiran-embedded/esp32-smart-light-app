import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/intro/cinematic_splash_screen.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/main/main_screen.dart';
import 'services/persistence_service.dart';
import 'services/firebase_switch_service.dart';
import 'providers/switch_provider.dart';
import 'providers/immersive_provider.dart';
import 'core/system/runtime_stability_buffer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Industry Level: Immersive Full-Screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

  // Stability Optimization
  RuntimeStabilityBuffer.optimize();

  runApp(
    ProviderScope(
      overrides: [
        switchDevicesProvider.overrideWith(
          (ref) => SwitchDevicesNotifier(ref, initialNicknames: nicknames),
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

    return MaterialApp(
      title: 'NEBULA CORE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeMode),
      // Composition Engine removed from global scope
      builder: (context, child) => child!,
      home: Listener(
        onPointerDown: (_) {
          // PRE-WARM CONNECTION: Wake up Firebase socket on functionality
          // This reduces the latency for the first write operation.
          ref.read(firebaseSwitchServiceProvider).preWarmConnection();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
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
    );
  }
}
