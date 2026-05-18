import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/glass_card.dart';

class SolutionScreen extends StatelessWidget {
  final VoidCallback onNext;

  const SolutionScreen({super.key, required this.onNext});

  static const _solutions = [
    (
      icon: '🎯',
      pain: "Don't know where to start",
      solution:
          'AI designs your personalized 30-day programme — habits, quests, and daily structure tailored to your life',
    ),
    (
      icon: '📊',
      pain: "Can't stay consistent",
      solution:
          'XP, streaks, and archetype evolution make progress visible and addictive',
    ),
    (
      icon: '🎙️',
      pain: 'No accountability',
      solution:
          'Voice-powered AI coach checks in, adapts to your progress, and keeps you honest',
    ),
    (
      icon: '⚡',
      pain: 'Overwhelmed',
      solution:
          "One day at a time. Open the app, see today's habits, do them. That's it.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                'Zenith is built for\nexactly this',
                style: ZenithTheme.cormorant(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 28),
              ...List.generate(_solutions.length, (i) {
                final s = _solutions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.pain,
                                style: ZenithTheme.dmSans(
                                  fontSize: 12,
                                  color: ZenithColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.solution,
                                style: ZenithTheme.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ZenithColors.text,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                      delay: (200 + i * 150).ms,
                      duration: 500.ms,
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
              onPressed: onNext,
              child: const Text('Build my programme'),
            ),
          ),
        ),
      ],
    );
  }
}
