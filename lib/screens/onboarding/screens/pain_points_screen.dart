import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/typewriter_text.dart';
import '../widgets/option_tile.dart';

class PainPointsScreen extends StatefulWidget {
  final List<String> selectedPainPoints;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const PainPointsScreen({
    super.key,
    required this.selectedPainPoints,
    required this.onToggle,
    required this.onNext,
  });

  @override
  State<PainPointsScreen> createState() => _PainPointsScreenState();
}

class _PainPointsScreenState extends State<PainPointsScreen> {
  bool _titleDone = false;

  static const _painPoints = [
    ('\u{1F636}', "I don't know where to start"),
    ('\u{1F4C9}', 'I start strong but lose momentum'),
    ('\u{1F937}', 'Other apps never stuck'),
    ('\u{23F0}', "I feel like there's never enough time"),
    ('\u{1F624}', 'I have no one holding me accountable'),
    ('\u{1F300}', 'I get overwhelmed trying to fix everything at once'),
    ('\u{1F4AD}', "I've lost confidence I can actually change"),
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
                text: "What's been holding you back?",
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
                ...List.generate(_painPoints.length, (i) {
                  final (emoji, label) = _painPoints[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OptionTile(
                      emoji: emoji,
                      label: label,
                      selected: widget.selectedPainPoints.contains(label),
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
              onPressed:
                  widget.selectedPainPoints.isNotEmpty ? widget.onNext : null,
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
