import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/sub_skill.dart';
import '../../../theme.dart';

class BeforeAfterPage extends StatefulWidget {
  final Map<String, int>? previousStats; // sub-skill XP at start of period
  final Map<String, int> currentStats; // sub-skill XP now
  final List<SubSkill> subSkills;
  final VoidCallback? onAnimationComplete;

  const BeforeAfterPage({
    super.key,
    this.previousStats,
    required this.currentStats,
    required this.subSkills,
    this.onAnimationComplete,
  });

  @override
  State<BeforeAfterPage> createState() => _BeforeAfterPageState();
}

class _BeforeAfterPageState extends State<BeforeAfterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Build the list of skills that gained XP.
  List<_SkillDelta> _buildDeltas() {
    final deltas = <_SkillDelta>[];
    final prev = widget.previousStats ?? {};

    for (final entry in widget.currentStats.entries) {
      final prevXP = prev[entry.key] ?? 0;
      final curXP = entry.value;
      if (curXP <= prevXP) continue;

      final skill = widget.subSkills
          .where((s) => s.id == entry.key)
          .firstOrNull;
      if (skill == null) continue;

      deltas.add(_SkillDelta(
        skill: skill,
        before: prevXP,
        after: curXP,
      ));
    }
    return deltas;
  }

  @override
  Widget build(BuildContext context) {
    final deltas = _buildDeltas();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(ZenithColors.primaryDeep, Colors.black, 0.4)!,
            ZenithColors.primary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'TRANSFORMATION',
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: ZenithColors.gold,
                ),
              ),
              const SizedBox(height: 24),

              if (deltas.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Keep going!',
                      style: ZenithTheme.cormorant(
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
                )
              else
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => ListView.separated(
                      itemCount: deltas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final d = deltas[index];
                        final progress =
                            Curves.easeOut.transform(_controller.value);
                        final animatedBefore =
                            (d.before * progress).round();
                        final animatedAfter =
                            (d.before + (d.after - d.before) * progress)
                                .round();
                        final maxXP =
                            d.after > 0 ? d.after.toDouble() : 1.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Skill header
                            Row(
                              children: [
                                Text(
                                  d.skill.icon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  d.skill.name,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Before / After row
                            Row(
                              children: [
                                // Before column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BEFORE',
                                        style: ZenithTheme.dmSans(
                                          fontSize: 10,
                                          letterSpacing: 2,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      Text(
                                        '$animatedBefore XP',
                                        style: ZenithTheme.mono(
                                          fontSize: 16,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: ZenithColors.gold,
                                    size: 18,
                                  ),
                                ),
                                // After column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'AFTER',
                                        style: ZenithTheme.dmSans(
                                          fontSize: 10,
                                          letterSpacing: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '$animatedAfter XP',
                                        style: ZenithTheme.mono(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                child: Stack(
                                  children: [
                                    // Background
                                    Container(
                                      color: Colors.white
                                          .withValues(alpha: 0.1),
                                    ),
                                    // Previous level
                                    FractionallySizedBox(
                                      widthFactor:
                                          (d.before / maxXP).clamp(0, 1),
                                      child: Container(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    // Current level (animated)
                                    FractionallySizedBox(
                                      widthFactor:
                                          ((d.before +
                                                      (d.after - d.before) *
                                                          progress) /
                                                  maxXP)
                                              .clamp(0, 1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: ZenithColors.gold,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillDelta {
  final SubSkill skill;
  final int before;
  final int after;

  const _SkillDelta({
    required this.skill,
    required this.before,
    required this.after,
  });
}
