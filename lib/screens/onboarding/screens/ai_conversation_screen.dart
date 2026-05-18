import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../services/ai_service.dart';
import '../../../theme.dart';
import '../onboarding_data.dart';

class AIConversationScreen extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onComplete;

  const AIConversationScreen({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<AIConversationScreen> createState() => _AIConversationScreenState();
}

class _AIConversationScreenState extends State<AIConversationScreen> {
  final _ai = AIService();
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();

  String _streamingReply = '';
  bool _isStreaming = false;
  bool _isRecording = false;
  bool _showTextInput = false;
  bool _showBuildButton = false;
  int _exchangeCount = 0;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  List<String> get _history => widget.data.conversationHistory;

  static const _readyToken = '[READY_TO_BUILD]';

  bool get _canBuild =>
      (_showBuildButton || _exchangeCount >= 6) && !_isStreaming;

  Future<void> _startConversation() async {
    setState(() {
      _isStreaming = true;
      _streamingReply = '';
    });

    // Inject questionnaire context as system_context at the start
    if (_history.isEmpty) {
      _history.add('system_context: ${_buildContextSummary()}');
    }

    try {
      int charCount = 0;
      await for (final chunk in _ai.streamOnboardingResponse(
        userName: widget.data.name,
        conversationHistory: _history,
      )) {
        if (!mounted) return;
        setState(() => _streamingReply += chunk);
        // Haptic on every ~8 characters for subtle typing feel
        charCount += chunk.length;
        if (charCount >= 8) {
          charCount = 0;
          HapticFeedback.selectionClick();
        }
      }
      if (!mounted) return;
      final reply = _streamingReply;
      setState(() {
        _history.add('coach: $reply');
        _isStreaming = false;
        _streamingReply = '';
      });
      _autoStartRecording();
    } catch (e) {
      if (!mounted) return;
      final fallback =
          "Hey ${widget.data.name}! I already know a bit about where you're at from the questionnaire. So \u2014 what do you want to achieve in the next 30 days? Dream big, be honest, say whatever comes to mind.";
      setState(() {
        _history.add('coach: $fallback');
        _isStreaming = false;
        _streamingReply = '';
      });
      _autoStartRecording();
    }
  }

  String _buildContextSummary() {
    final d = widget.data;
    return 'Goal areas: ${d.selectedGoals.isNotEmpty ? d.selectedGoals.join(', ') : 'not specified'}, '
        'Pain points: ${d.selectedPainPoints.join(', ')}, '
        'Preferred activities: ${d.selectedPreferences.join(', ')}';
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _textController.clear();
    setState(() {
      _history.add('user: $text');
      _exchangeCount++;
      _showTextInput = false;
    });

    await _streamReply();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      setState(() => _showTextInput = true);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/onboarding_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    setState(() => _isRecording = true);
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();

    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;

    setState(() {
      _history.add('user: [Voice message]');
      _exchangeCount++;
      _isStreaming = true;
      _streamingReply = '';
    });

    try {
      int charCount = 0;
      await for (final chunk in _ai.streamOnboardingResponseFromAudio(
        audioFile: file,
        userName: widget.data.name,
        conversationHistory: _history,
      )) {
        if (!mounted) return;
        setState(() => _streamingReply += chunk);
        charCount += chunk.length;
        if (charCount >= 8) {
          charCount = 0;
          HapticFeedback.selectionClick();
        }
      }
      if (!mounted) return;
      _finishReply(_streamingReply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStreaming = false;
        _streamingReply = '';
      });
    }
  }

  Future<void> _streamReply() async {
    setState(() {
      _isStreaming = true;
      _streamingReply = '';
    });

    try {
      int charCount = 0;
      await for (final chunk in _ai.streamOnboardingResponse(
        userName: widget.data.name,
        conversationHistory: _history,
      )) {
        if (!mounted) return;
        setState(() => _streamingReply += chunk);
        charCount += chunk.length;
        if (charCount >= 8) {
          charCount = 0;
          HapticFeedback.selectionClick();
        }
      }
      if (!mounted) return;
      _finishReply(_streamingReply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStreaming = false;
        _streamingReply = '';
      });
    }
  }

  void _finishReply(String reply) {
    final hasToken = reply.contains(_readyToken);
    final cleanReply = reply.replaceAll(_readyToken, '').trim();
    setState(() {
      _history.add('coach: $cleanReply');
      _isStreaming = false;
      _streamingReply = '';
      if (hasToken) _showBuildButton = true;
    });
    if (!hasToken) _autoStartRecording();
  }

  void _autoStartRecording() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isRecording && !_isStreaming && !_showTextInput && !_showBuildButton) {
        _startRecording();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            'What do you want to achieve\nin the next 30 days?',
            textAlign: TextAlign.center,
            style: ZenithTheme.cormorant(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's define your goal together",
          style: ZenithTheme.dmSans(
            fontSize: 13,
            color: ZenithColors.textLight,
          ),
        ),

        // Message area — pinned to top
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: _buildMessageArea(),
          ),
        ),

        // Build programme button — appears after 3+ exchanges
        if (_canBuild)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onComplete,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Build my custom programme'),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: ZenithColors.bg,
            border: Border(
              top: BorderSide(color: ZenithColors.cardBorder),
            ),
          ),
          child: SafeArea(
            top: false,
            child: _showTextInput ? _buildTextInput() : _buildVoiceInput(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageArea() {
    // Streaming — show text growing character by character
    if (_isStreaming && _streamingReply.isNotEmpty) {
      final displayText = _streamingReply.replaceAll(_readyToken, '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'COACH',
            style: ZenithTheme.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: ZenithColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: displayText),
                TextSpan(
                  text: ' \u258C',
                  style: ZenithTheme.dmSans(
                    fontSize: 17,
                    color: ZenithColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            style: ZenithTheme.dmSans(
              fontSize: 17,
              color: ZenithColors.text,
              height: 1.65,
            ),
          ),
        ],
      );
    }

    // Thinking
    if (_isStreaming) return _buildThinking();

    // Latest coach message
    final coachMessages =
        _history.where((m) => m.startsWith('coach:')).toList();
    if (coachMessages.isEmpty) return const SizedBox.shrink();
    final latest = coachMessages.last.replaceFirst('coach: ', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COACH',
          style: ZenithTheme.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: ZenithColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          latest,
          style: ZenithTheme.dmSans(
            fontSize: 17,
            color: ZenithColors.text,
            height: 1.65,
          ),
        ),
      ],
    )
        .animate(key: ValueKey(latest))
        .fadeIn(duration: 400.ms);
  }

  Widget _buildThinking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Coach is thinking...',
          style: ZenithTheme.dmSans(
            fontSize: 14,
            color: ZenithColors.textLight,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ZenithColors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: (i * 200).ms)
                .then()
                .fadeOut(delay: 400.ms);
          }),
        ),
      ],
    );
  }

  Widget _buildVoiceInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showTextInput = true),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: ZenithColors.cardBorder),
            ),
            child: Icon(
              Icons.keyboard_rounded,
              color: ZenithColors.textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: _isStreaming
              ? null
              : (_isRecording ? _stopRecording : _startRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isRecording ? 72 : 60,
            height: _isRecording ? 72 : 60,
            decoration: BoxDecoration(
              color: _isStreaming
                  ? ZenithColors.textMuted
                  : _isRecording
                      ? ZenithColors.danger
                      : ZenithColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording
                          ? ZenithColors.danger
                          : ZenithColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isStreaming
                  ? Icons.hourglass_top_rounded
                  : _isRecording
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
              color: Colors.white,
              size: _isRecording ? 32 : 28,
            ),
          ),
        ),
        const SizedBox(width: 20),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showTextInput = false),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: ZenithColors.cardBorder),
            ),
            child: Icon(
              Icons.mic_rounded,
              color: ZenithColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _textController,
            style: ZenithTheme.dmSans(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Type your response...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: ZenithColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: ZenithColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: ZenithColors.primary.withValues(alpha: 0.4),
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.6),
            ),
            onSubmitted: (_) => _sendTextMessage(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isStreaming ? null : _sendTextMessage,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZenithColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isStreaming
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
