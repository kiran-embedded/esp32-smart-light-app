import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/persistence_service.dart';

enum AuthState { initial, authenticated, unauthenticated, unconfigured }

enum ConnectionMode { local, cloud, hybrid }

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final localIpProvider = StateNotifierProvider<LocalIpNotifier, String?>((ref) {
  return LocalIpNotifier();
});

class LocalIpNotifier extends StateNotifier<String?> {
  LocalIpNotifier() : super(null) {
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('local_ip');
  }

  Future<void> setIp(String ip) async {
    state = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_ip', ip);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(AuthState.initial) {
    _checkAuthStatus();
    if (Firebase.apps.isNotEmpty) {
      _listenToAuthChanges();
    }
  }

  void _listenToAuthChanges() {
    final authService = _ref.read(authServiceProvider);
    authService.authStateChanges.listen((user) async {
      if (user != null) {
        state = AuthState.authenticated;
      } else {
        // Double check local/json auth before reverting to unauthenticated
        await _checkAuthStatus();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    final config = await PersistenceService.getFirebaseConfig();
    if (config == null) {
      state = AuthState.unconfigured;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonAuth = prefs.getBool('json_authenticated') ?? false;
    final localAuth = prefs.getBool('local_authenticated') ?? false;

    if (jsonAuth || localAuth) {
      state = AuthState.authenticated;
      return;
    }

    // Check if Firebase is actually initialized
    if (Firebase.apps.isEmpty) {
      state = AuthState.unauthenticated; // Or maybe stay in unconfigured?
      return;
    }

    final authService = _ref.read(authServiceProvider);
    try {
      final user = authService.currentUser;
      state = user != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> signIn() async {
    try {
      final authService = _ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        state = AuthState.authenticated;
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign in using imported google-services.json
  Future<void> signInWithJson(Map<String, dynamic> jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_json_config', jsonData.toString());
      await prefs.setBool('is_authenticated', true);
      await prefs.setBool('json_authenticated', true);
      state = AuthState.authenticated;
    } catch (e) {
      throw Exception('JSON authentication failed: $e');
    }
  }

  /// Sign in locally using an IP address
  Future<void> signInLocally(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_authenticated', true);
      await prefs.setBool('is_authenticated', true);
      await _ref.read(localIpProvider.notifier).setIp(ip);
      state = AuthState.authenticated;
    } catch (e) {
      throw Exception('Local connection failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      await prefs.setBool('json_authenticated', false);
      await prefs.setBool('local_authenticated', false);
      state = AuthState.unauthenticated;
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}

final connectionModeProvider =
    StateNotifierProvider<ConnectionModeNotifier, ConnectionMode>((ref) {
      return ConnectionModeNotifier();
    });

class ConnectionModeNotifier extends StateNotifier<ConnectionMode> {
  ConnectionModeNotifier() : super(ConnectionMode.hybrid) {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('connection_mode') ?? 2;
    state = ConnectionMode.values[modeIndex];
  }

  Future<void> setMode(ConnectionMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('connection_mode', mode.index);
  }
}
