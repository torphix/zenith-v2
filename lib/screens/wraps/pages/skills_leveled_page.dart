import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/sub_skill.dart';
import '../../../theme.dart';

class SkillsLeveledPage extends StatefulWidget {
  final Map<String, int> statsGained; // subSkillId -> XP gained
  final List<SubSkill> subSkills;
  final VoidCallback? onAnimationComplete;

  const SkillsLeveledPage({
    super.key,
    required this.statsGained,
    required this.subSkills,
    this.onAnimationComplete,
  });

  @override
  State<SkillsLeveledPage> createState() => _SkillsLeveledPageState();
}

class _SkillsLeveledPageState extends State<SkillsLeveledPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Calculate total animation time: number of items * 150ms stagger + 500ms buffer
    final itemCount = widget.statsGained.length;
    final totalDelay = itemCount * 150 + 500;
    _timer = Timer(Duration(milliseconds: totalDelay), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group statsGained by domain
    final domainGroups = <String, List<MapEntry<SubSkill, int>>>{};
    for (final entry in widget.statsGained.entries) {
      final skill = widget.subSkills
          .where((s) => s.id == entry.key)
          .firstOrNull;
      if (skill == null) continue;
      domainGroups.putIfAbsent(skill.domain, () => []);
      domainGroups[skill.domain]!.add(MapEntry(skill, entry.value));
    }

    var itemIndex = 0;

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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'SKILLS LEVELED',
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Domain groups
              Expanded(
                child: ListView(
                  children: [
                    for (final domainId in domainGroups.keys) ...[
                      _buildDomainGroup(
                        domainId,
                        domainGroups[domainId]!,
                        itemIndex,
                      ),
                      // Update itemIndex after building
                      Builder(builder: (_) {
                        itemIndex += domainGroups[domainId]!.length;
                        return const SizedBox(height: 20);
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainGroup(
    String domainId,
    List<MapEntry<SubSkill, int>> skills,
    int startIndex,
  ) {
    final domain = Domain.byId(domainId);
    final domainColor = domain?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Domain header
        Row(
          children: [
            Text(
              domain?.icon ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              domain?.label ?? domainId,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: domainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Skills
        for (var i = 0; i < skills.length; i++)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                Text(
                  skills[i].key.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skills[i].key.name,
                    style: ZenithTheme.dmSans(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '+${skills[i].value} XP',
                  style: ZenithTheme.mono(
                    fontSize: 14,
                    color: ZenithColors.gold,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: ((startIndex + i) * 150).ms,
                )
                .slideX(
                  begin: 0.15,
                  end: 0,
                  duration: 400.ms,
                  delay: ((startIndex + i) * 150).ms,
                ),
          ),
      ],
    );
  }
}
