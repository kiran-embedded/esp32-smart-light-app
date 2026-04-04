import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

final backgroundServiceProvider =
    StateNotifierProvider<BackgroundServiceNotifier, bool>((ref) {
      return BackgroundServiceNotifier();
    });

class BackgroundServiceNotifier extends StateNotifier<bool> {
  static const String _key = 'backgroundRunningEnabled';
  static final MethodChannel _channel = MethodChannel(
    'com.iot.nebulacontroller/native_scheduler',
  );

  BackgroundServiceNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    state = enabled;

    try {
      if (enabled) {
        await _channel.invokeMethod('startNativeSecurity');
      } else {
        await _channel.invokeMethod('stopNativeSecurity');
      }
    } catch (e) {
      print('MethodChannel background service toggle failed: $e');
    }
  }
}
