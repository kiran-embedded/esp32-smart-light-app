import 'dart:ui';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../services/haptic_service.dart';

class AiAssistantDialog extends ConsumerStatefulWidget {
  const AiAssistantDialog({super.key});

  @override
  ConsumerState<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends ConsumerState<AiAssistantDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        HapticService.heavy();
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _controller.text = _lastWords;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.isNotEmpty) {
        _handleSubmitted(_controller.text);
      }
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiAssistantProvider.notifier).sendMessage(text.trim());
    _controller.clear();
    HapticService.selection();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);

    // Auto-scroll on new messages
    ref.listen(aiAssistantProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Chat Messages
              Expanded(
                child: aiState.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: aiState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = aiState.messages[index];
                          return _buildChatBubble(msg);
                        },
                      ),
              ),

              if (aiState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: CupertinoActivityIndicator(
                    color: Colors.deepPurpleAccent,
                  ),
                ),

              if (aiState.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    aiState.error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Input Area
              _buildInputArea(context, aiState.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurpleAccent, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nebula AI',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Online',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (ref.watch(aiAssistantProvider).isSpeaking) ...[
                        const SizedBox(width: 6),
                        Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.5, 1.5),
                              duration: 600.ms,
                            )
                            .fadeOut(duration: 600.ms),
                        const SizedBox(width: 4),
                        Text(
                          'Speaking...',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.deepPurpleAccent.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              HapticService.selection();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                Icons.forum_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.1),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2.seconds,
                color: Colors.deepPurpleAccent.withOpacity(0.3),
              ),
          const SizedBox(height: 16),
          Text(
            "Hello! I'm Nebula. ✨\nHow can I help you today? 🌸",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          _buildQuickCommand('🌸 Turn on all lights'),
          _buildQuickCommand('🛡️ Arm security system'),
          _buildQuickCommand('🚀 Tell me about your processor'),
        ],
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildQuickCommand(String text) {
    return GestureDetector(
      onTap: () => _handleSubmitted(text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(AiChatMessage msg) {
    // Clean commands from text for display
    final displayText = msg.text
        .replaceAll(RegExp(r'\[COMMAND:.*?\]'), '')
        .trim();
    if (displayText.isEmpty && !msg.isUser) return const SizedBox.shrink();

    final isUser = msg.isUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(Icons.auto_awesome, Colors.deepPurpleAccent),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.deepPurpleAccent.withOpacity(0.8)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
                border: !isUser && ref.watch(aiAssistantProvider).isSpeaking
                    ? Border.all(
                        color: Colors.deepPurpleAccent.withOpacity(0.5),
                        width: 1,
                      )
                    : null,
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : (!isUser && ref.watch(aiAssistantProvider).isSpeaking
                          ? [
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null),
              ),

              child: MarkdownBody(
                data: displayText,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  strong: GoogleFonts.outfit(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().slideX(begin: isUser ? 0.1 : -0.1),
          if (isUser) ...[
            const SizedBox(width: 10),
            _buildAvatar(Icons.person, Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isLoading) {
    final aiState = ref.watch(aiAssistantProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Interactive Options (Help Center style)
        if (aiState.activeOptions.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: aiState.activeOptions.length,
              itemBuilder: (context, index) {
                final option = aiState.activeOptions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
                    side: BorderSide(
                      color: Colors.deepPurpleAccent.withOpacity(0.5),
                    ),
                    onPressed: () => _handleSubmitted(option),
                  ),
                );
              },
            ),
          ).animate().fadeIn().slideY(begin: 0.5),

        // Waveform Animation (Gemini Style)
        if (aiState.isSpeaking || _isListening)
          const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: GeminiWaveform(),
          ),

        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onSubmitted: (val) => _handleSubmitted(val),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening...'
                          : 'Type a command...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onLongPressStart: (_) => _listen(),
                onLongPressEnd: (_) => _listen(),
                onTap: () {
                  if (_controller.text.isNotEmpty) {
                    _handleSubmitted(_controller.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hold to speak'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child:
                    Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: _isListening
                                ? const LinearGradient(
                                    colors: [
                                      Colors.redAccent,
                                      Colors.orangeAccent,
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Colors.deepPurpleAccent,
                                      Colors.blueAccent,
                                    ],
                                  ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isListening
                                            ? Colors.redAccent
                                            : Colors.deepPurpleAccent)
                                        .withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.mic
                                : (_controller.text.isEmpty
                                      ? Icons.mic_none
                                      : Icons.send),
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                        .animate(target: _isListening ? 1.0 : 0.0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        )
                        .shimmer(
                          duration: 1.seconds,
                          color: Colors.white.withOpacity(0.5),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GeminiWaveform extends StatefulWidget {
  const GeminiWaveform({super.key});

  @override
  State<GeminiWaveform> createState() => _GeminiWaveformState();
}

class _GeminiWaveformState extends State<GeminiWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 40),
          painter: WaveformPainter(_controller.value),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  WaveformPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final List<Color> colors = [
      Colors.blueAccent,
      Colors.deepPurpleAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];

    for (int i = 0; i < colors.length; i++) {
      final path = Path();
      paint.color = colors[i].withOpacity(0.6);

      final phase = progress * 2 * 3.14159 + (i * 0.8);
      final amplitude = 15.0 * (1 - (i * 0.2));

      path.moveTo(0, size.height / 2);
      for (double x = 0; x <= size.width; x++) {
        final y =
            size.height / 2 +
            sin(x * 0.05 + phase) * amplitude * sin(x / size.width * 3.14159);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
