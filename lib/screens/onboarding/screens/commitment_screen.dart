import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/typewriter_text.dart';

class CommitmentScreen extends StatefulWidget {
  final String selectedLevel;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  const CommitmentScreen({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
    required this.onNext,
  });

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> {
  bool _titleDone = false;

  static const _levels = [
    ('\u{1F331}', '15', '15 min', 'Start small, build momentum'),
    ('\u{26A1}', '30', '30 min', 'The sweet spot for most people'),
    ('\u{1F525}', '45', '45 min', 'Serious about change'),
    ('\u{1F48E}', '60', '60 min', 'All in'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              TypewriterText(
                text: 'How much time can you commit each day?',
                charDuration: const Duration(milliseconds: 35),
                onComplete: () => setState(() => _titleDone = true),
              ),
              const SizedBox(height: 28),
              if (_titleDone)
                ...List.generate(_levels.length, (i) {
                  final (emoji, value, label, subtitle) = _levels[i];
                  final selected = widget.selectedLevel == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSelected(value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: selected
                              ? ZenithColors.primary.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? ZenithColors.primary.withValues(alpha: 0.4)
                                : ZenithColors.cardBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: ZenithTheme.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? ZenithColors.primary
                                          : ZenithColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: ZenithTheme.dmSans(
                                      fontSize: 13,
                                      color: ZenithColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: ZenithColors.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 80).ms, duration: 350.ms)
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        delay: (i * 80).ms,
                        duration: 350.ms,
                      );
                }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
