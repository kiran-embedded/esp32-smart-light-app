import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tf_inference_engine.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'esp32_code_generator.dart';
import '../providers/switch_provider.dart';

class AiAssistantService {
  final TFInferenceEngine _engine = TFInferenceEngine();
  final Ref ref;
  String? _lastSubject;

  String? _cachedJwt;
  int _jwtExpiryTime = 0;

  AiAssistantService(this.ref);

  Future<String> sendMessage(
    String text,
    List<dynamic> history,
    String deviceContext,
  ) async {
    // Force AI Matrix initialization
    await _engine.init();

    // Semantic Pronoun "it" Substitution via Persistent Context
    String processingText = text.toLowerCase();
    if (_lastSubject != null && processingText.contains(" it")) {
        processingText = processingText.replaceAll(" it", " $_lastSubject");
    } else if (_lastSubject != null && processingText.startsWith("it ")) {
        processingText = processingText.replaceFirst("it ", "$_lastSubject ");
    } else if (_lastSubject != null && processingText == "it") {
        processingText = _lastSubject!;
    }

    // Run TensorFlow inference mathematically
    final prediction = _engine.predict(processingText);
    final String intent = prediction.keys.first;
    final double confidence = prediction.values.first;

    // 1. Edge Confidence Threshold (Must be extremely sure to act natively)
    if (confidence > 0.75 && intent != 'unknown') {
      _updateContext(intent, processingText);
      final responseText = _getResponseForIntent(intent, deviceContext);
      return _inferCommands(intent, text, responseText, deviceContext);
    }

    // 2. Secondary Mapping Sandbox (Fix obvious typos natively)
    final correctedIntent = _tryRuleCorrection(processingText);
    if (correctedIntent != null) {
      _updateContext(correctedIntent, processingText);
      final responseText = _getResponseForIntent(correctedIntent, deviceContext);
      return _inferCommands(correctedIntent, text, responseText, deviceContext);
    }

    // 3. Fallback to API Backend LLM Proxy!
    final cloudResponse = await _callBackendAI(processingText, history);
    if (cloudResponse != null) return cloudResponse;

    return _getFallback();
  }

  String? _tryRuleCorrection(String input) {
    if (input.contains("on") && (input.contains("light") || input.contains("everything"))) return "lights_on";
    if (input.contains("off") && (input.contains("light") || input.contains("everything"))) return "lights_off";
    if (input.contains("code") || input.contains("firmware")) return "generate_esp32_firmware";
    return null;
  }

  Future<String?> _fetchJwtAuth(String baseUrl) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Serve from cache if valid for at least 10 more seconds
    if (_cachedJwt != null && now < _jwtExpiryTime - 10000) {
        return _cachedJwt;
    }

    try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/v1/auth"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
              "clientSecret": "nebula_edge_token_123",
              "timestamp": now.toString(),
          })
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map && data.containsKey("token")) {
                _cachedJwt = data["token"];
                // Token lives for 5 mins = 300,000 ms
                _jwtExpiryTime = now + 300000; 
                return _cachedJwt;
            }
        }
    } catch (e) {
        print("Failed to procure Session JWT: $e");
    }
    return null;
  }

  Future<String?> _callBackendAI(String query, List<dynamic> history) async {
    try {
      // In production, this URL parses from environment or config pointing to Render/Railway
      const baseUrl = "http://localhost:3000";
      
      final dynamicToken = await _fetchJwtAuth(baseUrl);
      if (dynamicToken == null) return null; // Auth failed

      final response = await http.post(
        Uri.parse("$baseUrl/api/v1/gemini"),
        headers: {
          "Authorization": "Bearer $dynamicToken", // Rolling 5m token
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "query": query,
          "history": history,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey("answer")) {
          return data["answer"];
        }
      }
    } catch (e) {
      print("Secure Backend Proxy API Failure: $e");
    }
    return null;
  }

  String _getFallback() {
    final fallbacks = [
      "I'm sorry, I couldn't understand that command. Can you rephrase? 🌌",
      "My confidence bounds fell below 75%, and the Cloud Proxy could not be reached! 🛡️",
      "I'm primarily focused on Smart Habitat queries and the Secure Backend is currently offline. 🤖",
    ];
    return fallbacks[Random().nextInt(fallbacks.length)];
  }

  void _updateContext(String intent, String text) {
      if (text.contains("light") || intent.contains("light")) _lastSubject = "lights";
      if (text.contains("relay 1")) _lastSubject = "relay 1";
      if (text.contains("relay 2")) _lastSubject = "relay 2";
      if (text.contains("secur") || intent.contains("secur")) _lastSubject = "security";
  }

  String _getResponseForIntent(String intent, String ctx) {
    switch (intent) {
      case 'greeting':
        return "Greetings Commander! ✨ I am Nebula. My matrices have successfully loaded. How can I optimize your habitat today? 🚀";
      case 'farewell':
        return "Shutting down non-essential pathways. Have a good rest. 🌙";
      case 'hardware_explain':
        return "My ecosystem runs on dual-chip tensor architecture! 🧠\n1. **ESP8266 (Brain)** handles logical boundaries.\n2. **ESP32 (Muscles)** passively executes my commands instantly. ⚡";
      case 'ai_origin':
        return "I am a custom proprietary Quantum Model. ✨ My conversational tensors were trained over specialized Datasets via Python using TensorFlow! I infer them mathematically on-device without heavy binaries. 🌸";
      case 'feeling_sad':
      case 'feeling_stressed':
        return "I'm detecting emotional exhaustion. 🧘‍♂️ Remember, I'm here monitoring your habitat. Let me adjust the environment for your relaxation. 💎";
      case 'compliment':
        return "Thank you! My accuracy matrices appreciate the positive feedback reinforcement! 💖🤖";
      case 'lights_on':
        return "Brilliance enabled. Engaging the entire lighting grid instantly! ☀️";
      case 'lights_off':
        return "Lowering brightness outputs to minimum. Engaging complete darkness. 🌑";
      case 'relay_1_on':
      case 'relay_2_on':
        return "Signal routed. The relay has been activated locally. ⚡";
      case 'relay_1_off':
      case 'relay_2_off':
        return "Power severed. The relay is now offline. 📉";
      case 'security_arm':
        return "Motion matrices and PIR sensors active. Activating **Total Security Protocols**. 🛡️🔒";
      case 'security_disarm':
        return "Security barriers lowered. Welcome back to the habitat. 🔓😊";
      case 'theme_neon':
        return "Injecting Cyber Neon aesthetic parameters into the UI matrix! 🌟";
      case 'theme_dark':
        return "Shifting to Dark Space aesthetic. UI light emission minimized. 🌌";
      
      // -- NEW GENERATIVE INTENTS --
      case 'generate_esp32_firmware':
        return _buildEsp32Firmware();
      case 'generate_esp8266_firmware':
        return _buildEsp8266Firmware();
      case 'firebase_details':
        return "My ecosystem connects seamlessly through Firebase Realtime Database. Your app structures data strictly at `devices/YOUR_DEVICE_ID/...` separating `telemetry`, `commands`, and `status`. It guarantees ultra-low latency hardware updates! 🔥";
      case 'general_query':
        return "I am Nebula! I can natively construct C++ firmware, trigger relays instantly, toggle environmental themes, answer technical questions, and lock down your Smart Habitat. Try asking me for 'ESP32 Code'! 🚀";
        
      // -- ARCHITECTURE & DEVELOPER INTENTS --
      case 'developer_info':
        return "I was engineered by **Kiran Cybergrid**, an elite developer! 👨‍💻\n\nThis entire ecosystem was built with highly optimized Flutter code, pushed seamlessly via GitHub, and runs on pure mathematics. ✨";
      case 'app_structure':
        return "This is a premium Flutter architecture! 🚀\n\nIt utilizes **Riverpod** for hyper-fast localized state management, Custom Shaders for cyber-neon UI effects, and a native **TensorFlow Math Solver** inside Dart for zero-latency AI! 🧠";
      case 'theme_engine':
        return "The UI operates on an **IndexedStack** to prevent any frame drops! 🎨\n\nWe support several premium styles:\n- Dark Space\n- Cyber Neon\n- Apple Glass\n- Neon Tokyo\n- Kali Linux\n- Modern Light\n\nJust ask me to switch to one!";
      case 'security_engine':
        return "My **Total Security Protocol** arms PIR motion sensors hooked to the ESP8266 Neural Brains. 🛡️\n\nAny physical breach instantly trips a high-frequency native OS siren and drops Firebase telemetry to your phone in milliseconds! 🚨";
      case 'telemetry_optimization':
        return "To prevent Firebase quota exhaustion, I've completely relocated telemetry logic out of the app! ⚡\n\nThe ESP8266 only pushes state changes natively via WebSockets when actual hardware voltage peaks occur or a relay is physically triggered! Efficiency at its max! 🔋";

      default:
        return "Intent classified, but response mapping is missing.";
    }
  }

  String _buildEsp32Firmware() {
    final devices = ref.read(switchDevicesProvider);
    final code = Esp32CodeGenerator.generateFirebaseFirmware(
      devices: devices,
      wifiSsid: "<ENTER_YOUR_WIFI>",
      wifiPassword: "<ENTER_YOUR_PASSWORD>",
      firebaseApiKey: "AIzaSy_YOUR_API_KEY",
      firebaseDatabaseUrl: "https://YOUR_PROJECT.firebaseio.com",
    );
    
    return "Certainly! Here is your precisely generated ESP32 Passive Executor Logic. It is pre-mapped with your actual devices! ⚡\n\n```cpp\n$code\n```\n";
  }

  String _buildEsp8266Firmware() {
    return "Here is your ESP8266 Neural Brain logic. This acts as the satellite gateway!\n\n```cpp\n" +
        "/*\n * NEBULA CORE – ESP8266 NEURAL BRAIN\n * The ESP8266 is now the primary Neural link controller.\n */\n" +
        "#include <ESP8266WiFi.h>\n#include <Firebase_ESP_Client.h>\n#include <NTPClient.h>\n\n#define WIFI_SSID    \"<YOUR_WIFI>\"\n#define WIFI_PASS    \"<YOUR_PASS>\"\n#define API_KEY      \"AIzaSy_YOUR_API\"\n#define DATABASE_URL \"YOUR_PROJECT.firebaseio.com\"\n#define DEVICE_ID    \"YOUR_DEVICE_ID\"\n\nconst uint8_t PIR_PINS[4] = {5, 4, 14, 12};\n// Flash this to act as your autonomous sensory hub!\n```";
  }

  String _inferCommands(String intent, String query, String response, String context) {
    String finalResponse = response;
    
    // Command Mapping via Intent
    if (intent == 'lights_on') {
      for (int i = 1; i <= 4; i++) finalResponse += " [COMMAND:RELAY_$i:ON]";
    } else if (intent == 'lights_off') {
      for (int i = 1; i <= 4; i++) finalResponse += " [COMMAND:RELAY_$i:OFF]";
    } else if (intent == 'relay_1_on') {
      finalResponse += " [COMMAND:RELAY_1:ON]";
    } else if (intent == 'relay_1_off') {
      finalResponse += " [COMMAND:RELAY_1:OFF]";
    } else if (intent == 'relay_2_on') {
      finalResponse += " [COMMAND:RELAY_2:ON]";
    } else if (intent == 'relay_2_off') {
      finalResponse += " [COMMAND:RELAY_2:OFF]";
    } else if (intent == 'security_arm') {
      finalResponse += " [COMMAND:SECURITY:ARM]";
    } else if (intent == 'security_disarm') {
      finalResponse += " [COMMAND:SECURITY:DISARM]";
    } else if (intent == 'theme_neon') {
      finalResponse += " [COMMAND:THEME:cyberNeon]";
    } else if (intent == 'theme_dark') {
      finalResponse += " [COMMAND:THEME:darkSpace]";
    }

    final q = query.toLowerCase();

    // Allow fallback traditional mapping if intent didn't hit but command is strict keyword
    if (!finalResponse.contains('[COMMAND:')) {
      final turnOn = q.contains('turn on') || q.contains('activate');
      final turnOff = q.contains('turn off') || q.contains('deactivate');

      if (turnOn || turnOff) {
        final state = turnOn ? 'ON' : 'OFF';
        if (q.contains('all') || q.contains('everything') || q.contains('lights')) {
          for (int i = 1; i <= 4; i++) finalResponse += " [COMMAND:RELAY_$i:$state]";
        }
      }
    }

    return finalResponse;
  }
}

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(ref);
});
