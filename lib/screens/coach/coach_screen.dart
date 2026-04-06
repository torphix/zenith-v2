import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/snackbar_helper.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  bool _isSending = false;
  bool _isRecording = false;
  bool _showTextInput = false;
  int _currentMessageIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() {
      _isSending = true;
      _showTextInput = false;
    });

    final app = context.read<AppProvider>();
    await app.sendCoachMessage(text);

    if (mounted) {
      final error = app.consumeError();
      if (error != null) {
        showErrorSnackbar(context, error);
      }
    }

    setState(() {
      _isSending = false;
      // Jump to latest coach reply
      _currentMessageIndex = app.chatMessages.length - 1;
    });
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/coach_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

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

  Future<void> _stopAndSend() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();

    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;

    setState(() => _isSending = true);

    final app = context.read<AppProvider>();

    // Upload, transcribe, then send to coach
    final transcript = await app.uploadAndTranscribeForCoach(file);
    if (transcript != null) {
      await app.sendCoachMessage(transcript);
    } else {
      if (mounted) {
        final error = app.consumeError();
        showErrorSnackbar(context, error ?? 'Failed to process voice message. Please try again.');
      }
    }

    setState(() {
      _isSending = false;
      _currentMessageIndex = app.chatMessages.length - 1;
    });
  }

  void _goToNext(int total) {
    if (_currentMessageIndex < total - 1) {
      setState(() => _currentMessageIndex++);
      HapticFeedback.selectionClick();
    }
  }

  void _goToPrev() {
    if (_currentMessageIndex > 0) {
      setState(() => _currentMessageIndex--);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final messages = app.chatMessages;
        final hasMessages = messages.isNotEmpty;

        return Scaffold(
          backgroundColor: ZenithColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ZenithColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: ZenithColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zenith Coach',
                            style: ZenithTheme.cormorant(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Voice-first coaching',
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              color: ZenithColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (hasMessages)
                        Text(
                          '${_currentMessageIndex + 1}/${messages.length}',
                          style: ZenithTheme.mono(
                            fontSize: 12,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Single message display ──
                Expanded(
                  child: hasMessages
                      ? GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity == null) return;
                            if (details.primaryVelocity! < -100) {
                              _goToNext(messages.length);
                            } else if (details.primaryVelocity! > 100) {
                              _goToPrev();
                            }
                          },
                          child: _isSending &&
                                  _currentMessageIndex == messages.length - 1
                              ? _ThinkingView()
                              : _SingleMessageView(
                                  key: ValueKey(_currentMessageIndex),
                                  message: messages[_currentMessageIndex],
                                ),
                        )
                      : _isSending
                          ? _ThinkingView()
                          : _EmptyCoach(),
                ),

                // ── Navigation dots ──
                if (hasMessages && messages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed:
                              _currentMessageIndex > 0 ? _goToPrev : null,
                          icon: Icon(Icons.chevron_left_rounded,
                              color: _currentMessageIndex > 0
                                  ? ZenithColors.text
                                  : ZenithColors.textMuted),
                          iconSize: 20,
                        ),
                        ...List.generate(
                          messages.length.clamp(0, 7),
                          (i) {
                            // Show dots around current position
                            final startIdx = messages.length <= 7
                                ? 0
                                : (_currentMessageIndex - 3)
                                    .clamp(0, messages.length - 7);
                            final dotIdx = startIdx + i;
                            if (dotIdx >= messages.length) {
                              return const SizedBox.shrink();
                            }
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentMessageIndex == dotIdx ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentMessageIndex == dotIdx
                                    ? ZenithColors.primary
                                    : ZenithColors.primaryPale,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: _currentMessageIndex < messages.length - 1
                              ? () => _goToNext(messages.length)
                              : null,
                          icon: Icon(Icons.chevron_right_rounded,
                              color:
                                  _currentMessageIndex < messages.length - 1
                                      ? ZenithColors.text
                                      : ZenithColors.textMuted),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),

                // ── Voice-first input area ──
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
                    child: _showTextInput
                        ? _buildTextInput()
                        : _buildVoiceInput(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Type instead button
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

        // Voice record button (large, center)
        GestureDetector(
          onTap: _isSending
              ? null
              : (_isRecording ? _stopAndSend : _startRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isRecording ? 72 : 60,
            height: _isRecording ? 72 : 60,
            decoration: BoxDecoration(
              color: _isSending
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
              _isSending
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

        // Spacer to keep mic centered
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        // Back to voice button
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
            controller: _controller,
            style: ZenithTheme.dmSans(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Type a message...',
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.6),
            ),
            onSubmitted: (_) => _send(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZenithColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSending
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

// ── Single message view (one at a time) ──

class _SingleMessageView extends StatelessWidget {
  final dynamic message;

  const _SingleMessageView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Role label
            Text(
              isUser ? 'You said' : 'Coach',
              style: ZenithTheme.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: ZenithColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // Message content
            GlassCard(
              padding: const EdgeInsets.all(24),
              color: isUser
                  ? ZenithColors.primary.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              child: Text(
                message.content,
                textAlign: TextAlign.center,
                style: ZenithTheme.dmSans(
                  fontSize: isUser ? 15 : 16,
                  color: ZenithColors.text,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Thinking/loading view ──

class _ThinkingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
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
      ),
    );
  }
}

// ── Empty state ──

class _EmptyCoach extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              size: 48,
              color: ZenithColors.primaryPale,
            ),
            const SizedBox(height: 16),
            Text(
              'Talk to your coach',
              style: ZenithTheme.cormorant(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the mic to start a voice conversation with your AI coach. '
              'Reflect on your day, ask for advice, or check in.',
              textAlign: TextAlign.center,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: ZenithColors.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
