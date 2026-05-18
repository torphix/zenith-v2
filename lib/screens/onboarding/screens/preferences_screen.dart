import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/typewriter_text.dart';

class PreferencesScreen extends StatefulWidget {
  final List<String> selectedPreferences;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const PreferencesScreen({
    super.key,
    required this.selectedPreferences,
    required this.onToggle,
    required this.onNext,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _titleDone = false;

  static const _prefs = [
    ('\u{1F3CB}\u{FE0F}', 'Working out'),
    ('\u{1F4D6}', 'Reading'),
    ('\u{1F9D8}', 'Meditation'),
    ('\u{1F4DD}', 'Journaling'),
    ('\u{1F6B6}', 'Walking / outdoors'),
    ('\u{1F373}', 'Cooking healthy'),
    ('\u{1F4BB}', 'Deep work / learning'),
    ('\u{1F634}', 'Better sleep'),
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
                text: 'What does your ideal day include?',
                charDuration: const Duration(milliseconds: 35),
                onComplete: () => setState(() => _titleDone = true),
              ),
              const SizedBox(height: 8),
              if (_titleDone)
                Text(
                  'Pick as many as you like',
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: ZenithColors.textLight,
                  ),
                ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              if (_titleDone)
                ...List.generate(_prefs.length, (i) {
                  final (emoji, label) = _prefs[i];
                  final selected =
                      widget.selectedPreferences.contains(label);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onToggle(label);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? ZenithColors.primary.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
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
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                label,
                                style: ZenithTheme.dmSans(
                                  fontSize: 15,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? ZenithColors.primary
                                      : ZenithColors.text,
                                ),
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
                      .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        delay: (i * 50).ms,
                        duration: 300.ms,
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
                  widget.selectedPreferences.isNotEmpty ? widget.onNext : null,
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
