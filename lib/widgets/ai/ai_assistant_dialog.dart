import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
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
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Input Area
            _buildInputArea(context, aiState.isLoading),
          ],
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
                  Text(
                    'Online',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w500,
                    ),
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
            'How can I help you today?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          _buildQuickCommand('Turn on all lights'),
          _buildQuickCommand('Is the kitchen light on?'),
          _buildQuickCommand('Set to Local Mode'),
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
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                displayText,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
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
                  hintText: _isListening ? 'Listening...' : 'Type a command...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
                                colors: [Colors.redAccent, Colors.orangeAccent],
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
                      duration: 500.ms,
                      curve: Curves.easeInOut,
                    ),
          ),
        ],
      ),
    );
  }
}
