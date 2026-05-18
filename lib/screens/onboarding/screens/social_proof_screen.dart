import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/glass_card.dart';

class SocialProofScreen extends StatelessWidget {
  final VoidCallback onNext;

  const SocialProofScreen({super.key, required this.onNext});

  static const _testimonials = [
    (
      name: 'Sam K.',
      tag: 'Full life resetter',
      text:
          "I tried everything. Zenith was the first thing that made me actually follow through for 30 days straight.",
    ),
    (
      name: 'Priya M.',
      tag: 'Busy professional',
      text:
          "Having my day planned out with exactly what to do — that's what finally made it click.",
    ),
    (
      name: 'Jordan T.',
      tag: 'Habit breaker',
      text:
          "Watching my archetype evolve from my actual habits was weirdly addictive. Day 30 hit and I didn't want to stop.",
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
                "You're not starting\nfrom zero",
                style: ZenithTheme.cormorant(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                'Join thousands building better lives, one day at a time',
                style: ZenithTheme.dmSans(
                  fontSize: 14,
                  color: ZenithColors.textLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 28),
              ...List.generate(_testimonials.length, (i) {
                final t = _testimonials[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: ZenithColors.primaryPale
                                  .withValues(alpha: 0.4),
                              child: Text(
                                t.name[0],
                                style: ZenithTheme.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ZenithColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  t.tag,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 12,
                                    color: ZenithColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"${t.text}"',
                          style: ZenithTheme.dmSans(
                            fontSize: 14,
                            color: ZenithColors.text,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                      delay: (300 + i * 150).ms,
                      duration: 500.ms,
                    );
              }),
              // Placeholder notice
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  // TODO: Replace with real testimonials
                  '',
                  style: ZenithTheme.dmSans(
                    fontSize: 11,
                    color: ZenithColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ),
      ],
    );
  }
}
