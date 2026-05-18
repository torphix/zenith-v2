import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/typewriter_text.dart';

class EnergyScreen extends StatefulWidget {
  final String selectedEnergy;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  const EnergyScreen({
    super.key,
    required this.selectedEnergy,
    required this.onSelected,
    required this.onNext,
  });

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  bool _titleDone = false;

  static const _styles = [
    ('\u{1F33F}', 'gentle', 'Gentle', 'Supportive nudges, self-compassion first'),
    ('\u{2696}\u{FE0F}', 'balanced', 'Balanced',
        'Firm but fair \u2014 push me when I need it'),
    ('\u{1F525}', 'intense', 'Intense',
        'No excuses. Hold me to a higher standard'),
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
                text: 'What coaching style fits you?',
                charDuration: const Duration(milliseconds: 35),
                onComplete: () => setState(() => _titleDone = true),
              ),
              const SizedBox(height: 28),
              if (_titleDone)
                ...List.generate(_styles.length, (i) {
                  final (emoji, value, label, subtitle) = _styles[i];
                  final selected = widget.selectedEnergy == value;
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
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: ZenithTheme.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? ZenithColors.primary
                                          : ZenithColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: ZenithTheme.dmSans(
                                      fontSize: 13,
                                      color: ZenithColors.textLight,
                                      height: 1.4,
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
                      .fadeIn(delay: (i * 100).ms, duration: 350.ms)
                      .slideX(
                        begin: 0.05,
                        end: 0,
                        delay: (i * 100).ms,
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
