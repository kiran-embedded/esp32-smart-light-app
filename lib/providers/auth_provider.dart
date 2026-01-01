import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/persistence_service.dart';

enum AuthState { initial, authenticated, unauthenticated, unconfigured }

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

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
    final isAuthenticated = prefs.getBool('is_authenticated') ?? false;

    if (jsonAuth || isAuthenticated) {
      state = AuthState.authenticated;
      return;
    }

    if (Firebase.apps.isEmpty) {
      state = AuthState.unauthenticated;
      return;
    }

    final authService = _ref.read(authServiceProvider);
    try {
      final user = authService.currentUser;
      if (user != null) {
        state = AuthState.authenticated;
        await prefs.setBool('is_authenticated', true);
      } else {
        state = AuthState.unauthenticated;
      }
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

  Future<void> signInWithJson(Map<String, dynamic> jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      await prefs.setBool('json_authenticated', true);
      state = AuthState.authenticated;
    } catch (e) {
      throw Exception('JSON authentication failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      await prefs.setBool('json_authenticated', false);
      state = AuthState.unauthenticated;
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
