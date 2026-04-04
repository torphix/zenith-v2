import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme.dart';


class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    final app = context.read<AppProvider>();
    await app.sendCoachMessage(text);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        _scrollToBottom();

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
                            'AI-powered guidance',
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              color: ZenithColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: app.chatMessages.isEmpty
                      ? _EmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: app.chatMessages.length +
                              (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == app.chatMessages.length &&
                                _isSending) {
                              return _TypingIndicator();
                            }
                            final msg = app.chatMessages[index];
                            final isUser = msg.role == 'user';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ChatBubble(
                                text: msg.content,
                                isUser: isUser,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 200.ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                        ),
                ),

                // Input
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: ZenithTheme.dmSans(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Ask your coach anything...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: ZenithColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: ZenithColors.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: ZenithColors.primary
                                      .withValues(alpha: 0.4),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: ZenithColors.primaryPale,
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI coach is ready',
              style: ZenithTheme.cormorant(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about your programme, get advice, or reflect on your progress.',
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

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? ZenithColors.primary
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: ZenithColors.cardBorder),
        ),
        child: Text(
          text,
          style: ZenithTheme.dmSans(
            fontSize: 14,
            color: isUser ? Colors.white : ZenithColors.text,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: ZenithColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ZenithColors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                )
                .fadeIn(delay: (i * 200).ms)
                .then()
                .fadeOut(delay: 400.ms);
          }),
        ),
      ),
    );
  }
}
