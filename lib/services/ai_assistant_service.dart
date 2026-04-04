import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_ai_engine.dart';

class AiAssistantService {
  final LocalAiEngine _engine = LocalAiEngine();

  Future<String> sendMessage(
    String text,
    List<dynamic>
    history, // Keep dynamic for now to avoid breaking provider immediately
    String deviceContext,
  ) async {
    // Process query locally using the new engine
    final response = await _engine.processQuery(text, deviceContext);

    // Add command simulation if the user asked for control (Logic kept for compatibility)
    // The provider handles the actual regex command parsing
    return _inferCommands(text, response, deviceContext);
  }

  String _inferCommands(String query, String response, String context) {
    final q = query.toLowerCase();
    String finalResponse = response;

    // Intelligent Command Inference - Relays
    final turnOn = q.contains('turn on') || q.contains('activate');
    final turnOff = q.contains('turn off') || q.contains('deactivate');

    if (turnOn || turnOff) {
      final state = turnOn ? 'ON' : 'OFF';

      // Multi-device: "All lights" or "everything"
      if (q.contains('all') ||
          q.contains('everything') ||
          q.contains('lights')) {
        for (int i = 1; i <= 4; i++) {
          finalResponse += " [COMMAND:RELAY_$i:$state]";
        }
      } else {
        // Individual relay - Parse by nickname from context first
        bool relayTriggered = false;

        // Extract nicknamed devices from context (e.g., "- relay1 (Fridge): OFF")
        final deviceRegex = RegExp(r'- (relay[1-4]) \((.*?)\):');
        final matches = deviceRegex.allMatches(context);

        for (final match in matches) {
          final rId = match.group(1);
          final nickname = match.group(2)?.toLowerCase() ?? "";
          final rNum = rId?.replaceAll('relay', '') ?? "";

          if (q.contains(nickname) && nickname.isNotEmpty) {
            finalResponse += " [COMMAND:RELAY_$rNum:$state]";
            relayTriggered = true;
            break;
          }
        }

        // Fallback to literal "relay X" or "X"
        if (!relayTriggered) {
          for (int i = 1; i <= 4; i++) {
            if (q.contains('relay $i') || q.contains('$i')) {
              finalResponse += " [COMMAND:RELAY_$i:$state]";
              break;
            }
          }
        }
      }
    }

    // Intelligent Command Inference - Security (Advanced)
    if (q.contains('arm') || q.contains('lock down') || q.contains('guard')) {
      finalResponse += " [COMMAND:SECURITY:ARM]";
    } else if (q.contains('disarm') ||
        q.contains('safe') ||
        q.contains('unlock')) {
      finalResponse += " [COMMAND:SECURITY:DISARM]";
    }

    // Intelligent Command Inference - Themes (Advanced)
    if (q.contains('theme') || q.contains('look') || q.contains('style')) {
      if (q.contains('cyber') || q.contains('neon')) {
        finalResponse += " [COMMAND:THEME:cyberNeon]";
      } else if (q.contains('dark') || q.contains('space')) {
        finalResponse += " [COMMAND:THEME:darkSpace]";
      } else if (q.contains('light') || q.contains('white')) {
        finalResponse += " [COMMAND:THEME:light]";
      } else if (q.contains('apple') || q.contains('glass')) {
        finalResponse += " [COMMAND:THEME:appleGlass]";
      } else if (q.contains('kali') || q.contains('hack')) {
        finalResponse += " [COMMAND:THEME:kaliLinux]";
      } else if (q.contains('tokyo') || q.contains('retro')) {
        finalResponse += " [COMMAND:THEME:neonTokyo]";
      }
    }

    return finalResponse;
  }
}

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService();
});
