import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/typewriter_text.dart';
import '../widgets/option_tile.dart';

class GoalScreen extends StatefulWidget {
  final List<String> selectedGoals;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const GoalScreen({
    super.key,
    required this.selectedGoals,
    required this.onToggle,
    required this.onNext,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  bool _titleDone = false;

  static const _goals = [
    ('\u{1F4AA}', 'Get my body right'),
    ('\u{1F9E0}', 'Sharpen my mind'),
    ('\u{1F4BC}', 'Level up my career'),
    ('\u{2764}\u{FE0F}', 'Strengthen my relationships'),
    ('\u{1F9D8}', 'Find inner peace'),
    ('\u{1F504}', 'Break bad habits'),
    ('\u{1F31F}', 'Everything \u2014 full life reset'),
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
                text: 'What areas of your life need the most attention?',
                charDuration: const Duration(milliseconds: 35),
                onComplete: () => setState(() => _titleDone = true),
              ),
              const SizedBox(height: 8),
              if (_titleDone)
                Text(
                  'Select all that apply',
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: ZenithColors.textLight,
                  ),
                ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              if (_titleDone)
                ...List.generate(_goals.length, (i) {
                  final (emoji, label) = _goals[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OptionTile(
                      emoji: emoji,
                      label: label,
                      selected: widget.selectedGoals.contains(label),
                      onTap: () => widget.onToggle(label),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 70).ms, duration: 350.ms)
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        delay: (i * 70).ms,
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
              onPressed: widget.selectedGoals.isNotEmpty ? widget.onNext : null,
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
