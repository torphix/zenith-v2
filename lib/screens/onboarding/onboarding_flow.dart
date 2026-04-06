import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../providers/app_provider.dart';
import '../../services/ai_service.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/snackbar_helper.dart';
import '../../widgets/typewriter_text.dart';
import '../main_shell.dart';

/// Onboarding steps shown in the left stepper.
enum _OnboardingStep {
  welcome(Icons.waving_hand_rounded, 'Welcome'),
  name(Icons.person_outline_rounded, 'Name'),
  conversation(Icons.chat_bubble_outline_rounded, 'Chat'),
  generating(Icons.auto_awesome_rounded, 'Programme');

  final IconData icon;
  final String label;
  const _OnboardingStep(this.icon, this.label);
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _ai = AIService();
  final _pageController = PageController();
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();

  int _currentPage = 0; // 0=welcome, 1=name, 2=chat, 3=generating
  String _name = '';

  // Chat state
  final List<String> _conversationHistory = []; // "user: ..." / "coach: ..."
  String _latestCoachMessage = '';
  bool _isThinking = false;
  bool _isRecording = false;
  bool _showTextInput = false;
  bool _isGenerating = false;
  int _exchangeCount = 0; // how many user messages sent

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ── Chat logic ──

  Future<void> _startConversation() async {
    setState(() => _isThinking = true);
    try {
      final reply = await _ai.getOnboardingResponse(
        userName: _name,
        conversationHistory: [],
      );
      setState(() {
        _latestCoachMessage = reply;
        _conversationHistory.add('coach: $reply');
        _isThinking = false;
      });
    } catch (e) {
      setState(() {
        _latestCoachMessage =
            'Hey $_name! Tell me — what\'s going on in your life right now? What areas do you feel like you want to improve?';
        _conversationHistory.add('coach: $_latestCoachMessage');
        _isThinking = false;
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isThinking) return;

    _textController.clear();
    setState(() {
      _conversationHistory.add('user: $text');
      _exchangeCount++;
      _isThinking = true;
      _showTextInput = false;
    });

    try {
      final reply = await _ai.getOnboardingResponse(
        userName: _name,
        conversationHistory: _conversationHistory,
      );
      _handleCoachReply(reply);
    } catch (e) {
      setState(() => _isThinking = false);
      if (mounted) showErrorSnackbar(context, 'Failed to get response. Try again.');
    }
  }

  Future<void> _sendVoiceMessage() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();

    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;

    setState(() {
      _conversationHistory.add('user: [Voice message]');
      _exchangeCount++;
      _isThinking = true;
    });

    try {
      final reply = await _ai.getOnboardingResponseFromAudio(
        audioFile: file,
        userName: _name,
        conversationHistory: _conversationHistory,
      );
      _handleCoachReply(reply);
    } catch (e) {
      setState(() => _isThinking = false);
      if (mounted) showErrorSnackbar(context, 'Failed to process voice. Try again.');
    }
  }

  void _handleCoachReply(String reply) {
    setState(() {
      _latestCoachMessage = reply;
      _conversationHistory.add('coach: $reply');
      _isThinking = false;
    });

    // Check if the AI signaled it's done
    final lower = reply.toLowerCase();
    if (_exchangeCount >= 4 &&
        (lower.contains('build your programme') ||
            lower.contains('let me build') ||
            lower.contains('craft your programme') ||
            lower.contains('create your programme') ||
            lower.contains('i have a great picture') ||
            _exchangeCount >= 7)) {
      Future.delayed(const Duration(seconds: 2), _finishOnboarding);
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

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

  // ── Finish ──

  Future<void> _finishOnboarding() async {
    setState(() => _isGenerating = true);
    _goToPage(3);

    final app = context.read<AppProvider>();
    await app.completeConversationalOnboarding(
      name: _name.trim().isEmpty ? 'Seeker' : _name.trim(),
      conversationHistory: _conversationHistory,
    );

    if (!mounted) return;

    final error = app.consumeError();
    if (error != null) {
      showErrorSnackbar(context, error);
      setState(() => _isGenerating = false);
      _goToPage(2); // Back to chat
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenithColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            // ── Left stepper ──
            _Stepper(currentStep: _currentPage),

            // ── Main content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: () => _goToPage(1)),
                  _NamePage(
                    name: _name,
                    onChanged: (v) => setState(() => _name = v),
                    onNext: () {
                      _goToPage(2);
                      _startConversation();
                    },
                  ),
                  _ChatPage(
                    latestMessage: _latestCoachMessage,
                    isThinking: _isThinking,
                    isRecording: _isRecording,
                    showTextInput: _showTextInput,
                    textController: _textController,
                    exchangeCount: _exchangeCount,
                    onSendText: _sendTextMessage,
                    onStartRecording: _startRecording,
                    onStopRecording: _sendVoiceMessage,
                    onToggleInput: () =>
                        setState(() => _showTextInput = !_showTextInput),
                    onFinish: _finishOnboarding,
                  ),
                  _GeneratingPage(isGenerating: _isGenerating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Left Stepper ──

class _Stepper extends StatelessWidget {
  final int currentStep;
  const _Stepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: ZenithColors.cardBorder),
        ),
      ),
      child: Column(
        children: _OnboardingStep.values.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isActive = i == currentStep;
          final isDone = i < currentStep;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ZenithColors.primary
                        : isDone
                            ? ZenithColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isDone
                          ? ZenithColors.primary
                          : ZenithColors.textMuted.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : step.icon,
                    size: 18,
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? ZenithColors.primary
                            : ZenithColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  style: ZenithTheme.dmSans(
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isActive ? ZenithColors.primary : ZenithColors.textMuted,
                  ),
                ),
                if (i < _OnboardingStep.values.length - 1) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 1.5,
                    height: 20,
                    color: isDone
                        ? ZenithColors.primary.withValues(alpha: 0.4)
                        : ZenithColors.textMuted.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Page 1: Welcome ──

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ZENITH',
            style: ZenithTheme.cormorant(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: 16,
              color: ZenithColors.primary,
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Your journey to the peak begins here.',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 16,
              color: ZenithColors.textLight,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            '30 days. Real change. No shortcuts.',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textMuted,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Begin'),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Page 2: Name ──

class _NamePage extends StatelessWidget {
  final String name;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _NamePage({
    required this.name,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          TypewriterText(
            text: 'What should we call you?',
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: onChanged,
            style: ZenithTheme.dmSans(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) {
              if (name.trim().isNotEmpty) onNext();
            },
          ).animate().fadeIn(delay: 800.ms),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: name.trim().isNotEmpty ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 3: AI Chat ──

class _ChatPage extends StatelessWidget {
  final String latestMessage;
  final bool isThinking;
  final bool isRecording;
  final bool showTextInput;
  final TextEditingController textController;
  final int exchangeCount;
  final VoidCallback onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onToggleInput;
  final VoidCallback onFinish;

  const _ChatPage({
    required this.latestMessage,
    required this.isThinking,
    required this.isRecording,
    required this.showTextInput,
    required this.textController,
    required this.exchangeCount,
    required this.onSendText,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onToggleInput,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Coach message area ──
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: isThinking ? _buildThinking() : _buildMessage(),
            ),
          ),
        ),

        // ── Exchange progress ──
        if (exchangeCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i < exchangeCount ? 20 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < exchangeCount
                        ? ZenithColors.primary
                        : ZenithColors.primaryPale.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

        // ── Input area ──
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
            child: showTextInput ? _buildTextInput() : _buildVoiceInput(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    if (latestMessage.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Coach',
          style: ZenithTheme.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: ZenithColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(24),
          color: Colors.white.withValues(alpha: 0.7),
          child: Text(
            latestMessage,
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 16,
              color: ZenithColors.text,
              height: 1.6,
            ),
          ),
        ),
      ],
    ).animate(key: ValueKey(latestMessage)).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
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
        // Type instead
        GestureDetector(
          onTap: onToggleInput,
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

        // Voice button
        GestureDetector(
          onTap: isThinking
              ? null
              : (isRecording ? onStopRecording : onStartRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 72 : 60,
            height: isRecording ? 72 : 60,
            decoration: BoxDecoration(
              color: isThinking
                  ? ZenithColors.textMuted
                  : isRecording
                      ? ZenithColors.danger
                      : ZenithColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRecording
                          ? ZenithColors.danger
                          : ZenithColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isThinking
                  ? Icons.hourglass_top_rounded
                  : isRecording
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
              color: Colors.white,
              size: isRecording ? 32 : 28,
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Spacer for symmetry
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        // Back to voice
        GestureDetector(
          onTap: onToggleInput,
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
            controller: textController,
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
            onSubmitted: (_) => onSendText(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSendText,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZenithColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isThinking
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

// ── Page 4: Generating ──

class _GeneratingPage extends StatelessWidget {
  final bool isGenerating;
  const _GeneratingPage({required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ZenithColors.primary.withValues(alpha: 0.6),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: ZenithColors.primaryLight),
            const SizedBox(height: 32),
            Text(
              'Crafting your programme',
              style: ZenithTheme.cormorant(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 12),
            Text(
              'Building a personalized 30-day plan based on our conversation.',
              textAlign: TextAlign.center,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: ZenithColors.textLight,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
