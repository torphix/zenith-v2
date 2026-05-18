import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';

class TinderCardsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const TinderCardsScreen({super.key, required this.onComplete});

  @override
  State<TinderCardsScreen> createState() => _TinderCardsScreenState();
}

class _TinderCardsScreenState extends State<TinderCardsScreen> {
  static const _statements = [
    "I keep saying 'I'll start Monday' but Monday never comes",
    "I know what I should be doing, I just... don't do it",
    "I've downloaded 10 self-improvement apps and abandoned all of them",
    "I feel like I'm wasting my potential and time is slipping away",
  ];

  int _currentCard = 0;
  double _dragX = 0;
  bool _isDragging = false;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragX.abs() > 80) {
      HapticFeedback.lightImpact();
      _advanceCard();
    } else {
      setState(() {
        _dragX = 0;
        _isDragging = false;
      });
    }
  }

  void _advanceCard() {
    if (_currentCard >= _statements.length - 1) {
      widget.onComplete();
    } else {
      setState(() {
        _currentCard++;
        _dragX = 0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'Swipe if this\nsounds like you',
            style: ZenithTheme.cormorant(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Card counter
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_statements.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentCard ? 20 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentCard
                    ? ZenithColors.primary
                    : ZenithColors.primaryPale.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
                duration:
                    _isDragging ? Duration.zero : const Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..translateByDouble(_dragX, 0, 0, 1)
                  ..rotateZ(_dragX * 0.001),
                child: _buildCard(),
              ),
            ),
          ),
        ),
        // Swipe hint
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_rounded,
                  size: 18, color: ZenithColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Swipe left or right',
                style: ZenithTheme.dmSans(
                  fontSize: 13,
                  color: ZenithColors.textMuted,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ),
      ],
    );
  }

  Widget _buildCard() {
    final opacity = (_dragX.abs() / 120).clamp(0.0, 1.0);
    final isRight = _dragX > 0;

    return Container(
      key: ValueKey(_currentCard),
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDragging
              ? (isRight
                  ? ZenithColors.primary.withValues(alpha: opacity)
                  : ZenithColors.danger.withValues(alpha: opacity))
              : ZenithColors.cardBorder,
          width: _isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDragging)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Icon(
                isRight ? Icons.check_rounded : Icons.close_rounded,
                color: isRight ? ZenithColors.primary : ZenithColors.danger,
                size: 28,
              ),
            ),
          Text(
            '"${_statements[_currentCard]}"',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ZenithColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(_currentCard)).fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }
}
