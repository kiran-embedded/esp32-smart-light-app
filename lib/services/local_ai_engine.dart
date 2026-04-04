import 'dart:math';
import 'package:expressions/expressions.dart';

class AiRule {
  final List<String> keywords;
  final RegExp? regex;
  final String Function(String query, String deviceContext) response;

  AiRule({this.keywords = const [], this.regex, required this.response});

  bool matches(String query) {
    final q = query.toLowerCase();
    if (regex != null && regex!.hasMatch(q)) return true;
    for (var k in keywords) {
      if (q.contains(k.toLowerCase())) return true;
    }
    return false;
  }
}

class LocalAiEngine {
  final List<AiRule> _rules = [
    // ADVANCED MATH ENGINE (Phase 20)
    AiRule(
      regex: RegExp(r'([\d\+\-\*\/\(\)\s\.x]+)'),
      response: (q, ctx) {
        // Only trigger if it looks like an equation (contains at least one operator)
        if (!q.contains(RegExp(r'[\+\-\*\/\x]'))) return ""; // Pass through

        try {
          final cleanExpr = q.replaceAll('x', '*').replaceAll('=', '').trim();
          final expression = Expression.parse(cleanExpr);
          const evaluator = ExpressionEvaluator();
          final result = evaluator.eval(expression, {});
          return "My Quantum math cores have finalized the calculation: $cleanExpr = **$result**. 🧠 Precision is absolute.";
        } catch (_) {
          return ""; // Fallback to other rules if parsing fails
        }
      },
    ),

    // EMOTIONAL RESPONSES (EQ UPGRADE)
    AiRule(
      keywords: ['lonely', 'sad', 'bad day', 'depressed', 'feel'],
      response: (q, ctx) =>
          "I'm truly sorry you're feeling this way. 🌸 Remember that you aren't alone—I'm here, monitoring your habitat and keeping you safe. Why don't we try a **Cyber Neon** theme to brighten the mood? ✨ or I can turn on some warm lights for you. 🕯️",
    ),
    AiRule(
      keywords: ['stressed', 'tired', 'exhausted'],
      response: (q, ctx) =>
          "It sounds like you need a break. 🧘‍♂️ I've optimized the habitat for relaxation. I'm here to handle the switches so you don't have to. You're doing a great job, Commander. 🛡️💎",
    ),

    // GREETINGS & PERSONALITY
    AiRule(
      keywords: ['hi', 'hello', 'hey', 'greetings', 'sup', 'yo'],
      response: (q, ctx) {
        final name =
            RegExp(r"USER:\s*(\w+)").firstMatch(ctx)?.group(1) ?? "Commander";
        return "Greetings, $name! ✨ I am Nebula, your Quantum Intelligent companion. My neural nets are primed for habitat management. How can I serve you today? 🚀";
      },
    ),

    // FULL HABITAT CONTROL
    AiRule(
      keywords: ['control', 'manage', 'everything', 'all'],
      response: (q, ctx) =>
          "I have **Total Sovereignty** over your grid. 🛡️ I can bridge any automation gap and optimize your world. Point me to a device, and I shall engage it. ✨",
    ),

    // SYSTEM ADVANCED
    AiRule(
      keywords: ['processor', 'cpu', 'chip', 'brain', 'ram'],
      response: (q, ctx) =>
          "I am running on localized **Xtensa® Dual-Core LX7** silicon. 🧠 Extremely lean, extremely fast. Background footprint: **<100MB**. ⚡",
    ),

    // ADVANCED CONTROLS
    AiRule(
      keywords: ['theme', 'look', 'style', 'color', 'ui'],
      response: (q, ctx) =>
          "I can reshape my aesthetic instantly! 🎨 Which pulse do you want to feel? **Neon Tokyo**, **Dark Space**, or **Apple Glass**? [ACTION:THEME_PICKER]",
    ),

    // SECURITY (EQ + IQ)
    AiRule(
      keywords: ['arm', 'lock down', 'security on', 'guard'],
      response: (q, ctx) =>
          "Engaging **Total Security Protocols**. 🛡️ Sleep well—I am the silent guardian of this habitat. 🔒✨ [COMMAND:SECURITY:ARM]",
    ),
    AiRule(
      keywords: ['disarm', 'safe', 'security off', 'unlock'],
      response: (q, ctx) =>
          "Lowering shields. 🔓 You are in a safe zone. Welcome back. 😊 [COMMAND:SECURITY:DISARM]",
    ),
  ];

  final List<String> _fallbacks = [
    "I'm sorry, I am the **Assistant of Nebula Core**. My intelligence is specialized for this habitat's management and your emotional support. 🌌",
    "Queries about external topics are outside my current logic cores. I am focused 100% on your **Smart Habitat** and your well-being. 🛡️🤖",
  ];

  Future<String> processQuery(String query, String deviceContext) async {
    final delay = Random().nextInt(40) + 10;
    await Future.delayed(Duration(milliseconds: delay));

    for (var rule in _rules) {
      if (rule.matches(query)) {
        final resp = rule.response(query, deviceContext);
        if (resp.isNotEmpty) return resp;
      }
    }

    return _fallbacks[Random().nextInt(_fallbacks.length)];
  }
}
