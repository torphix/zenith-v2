import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Text(
            'ZENITH',
            style: ZenithTheme.cormorant(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: 16,
              color: ZenithColors.primary,
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'Your next 30 days\nstart here',
            textAlign: TextAlign.center,
            style: ZenithTheme.cormorant(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: ZenithColors.text,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'A personalized programme built by AI.\nHabits that stick. Progress you can see.',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 15,
              color: ZenithColors.textLight,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text("Let's go"),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
