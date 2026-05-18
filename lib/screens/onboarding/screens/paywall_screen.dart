import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';
import '../../../widgets/glass_card.dart';

class PaywallScreen extends StatelessWidget {
  final VoidCallback onStartTrial;
  final VoidCallback onSkip;

  const PaywallScreen({
    super.key,
    required this.onStartTrial,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              // Logo & headline
              Center(
                child: Text(
                  'ZENITH',
                  style: ZenithTheme.cormorant(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 12,
                    color: ZenithColors.primary,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                'Your transformation\nstarts now',
                textAlign: TextAlign.center,
                style: ZenithTheme.cormorant(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                '30 days. Real change. No shortcuts.',
                textAlign: TextAlign.center,
                style: ZenithTheme.dmSans(
                  fontSize: 14,
                  color: ZenithColors.textLight,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 28),

              // Testimonial
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (_) => Icon(
                          Icons.star_rounded,
                          color: ZenithColors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"The only app that actually changed my daily routine."',
                      textAlign: TextAlign.center,
                      style: ZenithTheme.dmSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: ZenithColors.text,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— Alex R.',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const SizedBox(height: 28),

              // Pricing
              // TODO: Connect to StoreKit (iOS) / Google Play Billing (Android)
              GlassCard(
                padding: const EdgeInsets.all(24),
                color: ZenithColors.primary.withValues(alpha: 0.04),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ZenithColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: ZenithTheme.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: ZenithColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start your FREE 7-day trial',
                      style: ZenithTheme.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ZenithColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$9.99/month after trial',
                      style: ZenithTheme.dmSans(
                        fontSize: 15,
                        color: ZenithColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or \$59.99/year (save 50%)',
                      style: ZenithTheme.dmSans(
                        fontSize: 13,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            ],
          ),
        ),

        // CTAs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // TODO: Implement subscription purchase
              onPressed: onStartTrial,
              child: const Text('Start Free Trial'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                // TODO: Implement restore purchases
                onPressed: () {},
                child: Text(
                  'Restore purchases',
                  style: ZenithTheme.dmSans(
                    fontSize: 12,
                    color: ZenithColors.textMuted,
                  ),
                ),
              ),
              Text(
                ' \u2022 ',
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  color: ZenithColors.textMuted,
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip for now',
                  style: ZenithTheme.dmSans(
                    fontSize: 12,
                    color: ZenithColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
