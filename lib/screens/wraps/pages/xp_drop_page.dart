import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/sub_skill.dart';
import '../../../theme.dart';
import '../widgets/stat_counter.dart';

class XpDropPage extends StatefulWidget {
  final int totalXP;
  final Map<String, int> statsGained; // subSkillId -> XP
  final List<SubSkill> subSkills; // for looking up names/icons
  final VoidCallback? onAnimationComplete;

  const XpDropPage({
    super.key,
    required this.totalXP,
    required this.statsGained,
    required this.subSkills,
    this.onAnimationComplete,
  });

  @override
  State<XpDropPage> createState() => _XpDropPageState();
}

class _XpDropPageState extends State<XpDropPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  final _random = Random(42);

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start shake after slam lands (800ms elastic)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _shakeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  SubSkill? _findSubSkill(String id) {
    for (final s in widget.subSkills) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.statsGained.entries.toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B3D2B), Color(0xFF3F5040)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // "XP EARNED" label
            Text(
              'XP EARNED',
              style: ZenithTheme.dmSans(
                fontSize: 12,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 16),

            // XP counter with slam + shake
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, shakeValue, child) {
                final dx = shakeValue *
                    (_random.nextDouble() * 6 - 3); // +/- 3px
                final dy = shakeValue *
                    (_random.nextDouble() * 6 - 3);
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: child,
                );
              },
              child: StatCounter(
                targetValue: widget.totalXP,
                prefix: '+',
                duration: const Duration(milliseconds: 1200),
                style: ZenithTheme.mono(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: ZenithColors.gold,
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: -0.5,
                  end: 0,
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),

            const Spacer(),

            // Stat gains list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  for (int i = 0; i < entries.length; i++)
                    _buildStatRow(entries[i], i),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(MapEntry<String, int> entry, int index) {
    final subSkill = _findSubSkill(entry.key);
    final name = subSkill?.name ?? entry.key;
    final icon = subSkill?.icon ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            '+${entry.value}',
            style: ZenithTheme.mono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ZenithColors.gold,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: 800 + index * 150),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: 800 + index * 150),
          curve: Curves.easeOut,
        );
  }
}
