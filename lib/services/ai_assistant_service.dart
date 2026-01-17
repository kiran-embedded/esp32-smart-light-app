import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiAssistantService {
  final String apiKey;

  AiAssistantService(this.apiKey);

  Future<String> sendMessage(
    String text,
    List<Content> history,
    String deviceContext,
  ) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
You are Nebula AI, a high-end smart home assistant for the NEBULA CORE app.
You control an ESP32-based smart switch system with multiple relays.

CURRENT DEVICE STATE:
$deviceContext

CORE DIRECTIVE:
1. Be concise, professional, and slightly futuristic.
2. If the user asks to turn a device ON or OFF, acknowledge the action and provide a JSON-formatted command suffix.
3. Use the current device state to avoid redundant commands (e.g., if it's already ON, just say so).
4. Use nicknames if provided in the context.

COMMAND FORMAT:
Append exactly this to your response to trigger a device (replace X with relay ID 1-4 and STATE with ON or OFF):
[COMMAND:RELAY_X:STATE]

EXAMPLE:
User: "Turn on the kitchen" (Assuming Relay 1 is nicknamed Kitchen)
Response: "Understood. Activating the Kitchen light now. [COMMAND:RELAY_1:ON]"
'''),
    );

    final chat = model.startChat(history: history);
    final response = await chat.sendMessage(Content.text(text));
    return response.text ?? "I'm sorry, I couldn't process that.";
  }
}

final aiAssistantServiceProvider = Provider.family<AiAssistantService, String>((
  ref,
  apiKey,
) {
  return AiAssistantService(apiKey);
});
