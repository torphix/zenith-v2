import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';

import '../../../theme.dart';
import '../../../widgets/glass_card.dart';

class MicPermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;
  final VoidCallback onSkip;

  const MicPermissionScreen({
    super.key,
    required this.onGranted,
    required this.onSkip,
  });

  Future<void> _requestPermission(BuildContext context) async {
    final recorder = AudioRecorder();
    try {
      final granted = await recorder.hasPermission();
      if (granted) {
        onGranted();
      } else {
        // Permission was denied — still continue
        onSkip();
      }
    } finally {
      recorder.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ZenithColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_rounded,
              size: 36,
              color: ZenithColors.primary,
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
              ),
          const SizedBox(height: 28),
          Text(
            'Talk to your coach,\nhands-free',
            textAlign: TextAlign.center,
            style: ZenithTheme.cormorant(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 32),
          ..._buildBenefits(),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _requestPermission(context),
              child: const Text('Enable voice'),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Not now',
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: ZenithColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildBenefits() {
    const benefits = [
      (Icons.mic_rounded, 'Speak your goals instead of typing'),
      (Icons.checklist_rounded, 'Voice-log tasks on the go'),
      (Icons.chat_bubble_rounded, 'Have real conversations with your coach'),
    ];

    return List.generate(benefits.length, (i) {
      final (icon, text) = benefits[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: ZenithColors.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: ZenithColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(
            delay: (300 + i * 100).ms,
            duration: 400.ms,
          );
    });
  }
}
