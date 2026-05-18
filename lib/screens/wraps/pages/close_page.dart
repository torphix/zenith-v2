import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/archetype.dart';
import '../../../theme.dart';

class ClosePage extends StatelessWidget {
  final int dayNumber;
  final double completionRate;
  final int totalXP;
  final Archetype archetype;
  final VoidCallback? onDone;

  const ClosePage({
    super.key,
    required this.dayNumber,
    required this.completionRate,
    required this.totalXP,
    required this.archetype,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A2E1A),
            ZenithColors.primaryDeep,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Day title
                  Text(
                    'Day $dayNumber',
                    style: ZenithTheme.cormorant(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Completion %
                      _StatColumn(
                        value: '${(completionRate * 100).round()}%',
                        label: 'Complete',
                      ),
                      // XP earned
                      _StatColumn(
                        value: '$totalXP',
                        label: 'XP Earned',
                      ),
                      // Archetype
                      Column(
                        children: [
                          Text(
                            archetype.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            archetype.name,
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: 32),

            // Done button
            GestureDetector(
              onTap: onDone,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Done',
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: ZenithTheme.mono(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ZenithTheme.dmSans(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
