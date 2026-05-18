import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/archetype.dart';
import '../../models/sub_skill.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';

class ArchetypeScreen extends StatelessWidget {
  const ArchetypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenithColors.bg,
      appBar: AppBar(
        title: Text(
          'Your Archetype',
          style: ZenithTheme.cormorant(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final archetype = app.archetype;
          final subSkills = app.subSkills;
          final stats = app.stats;
          final domainTotals = stats.domainTotals(subSkills);
          final matchScores = Archetype.matchScores(domainTotals);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── 1. Hero Section ──
                  _HeroSection(archetype: archetype),

                  const SizedBox(height: 28),

                  // ── 2. Radar Chart ──
                  _RadarChartSection(
                    archetype: archetype,
                    domainTotals: domainTotals,
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 28),

                  // ── 3. Sub-skills by Domain ──
                  _SubSkillsSection(
                    archetype: archetype,
                    subSkills: subSkills,
                  ),

                  const SizedBox(height: 28),

                  // ── 4. Archetype Gallery ──
                  _ArchetypeGallery(
                    currentArchetype: archetype,
                    matchScores: matchScores,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Archetype archetype;

  const _HeroSection({required this.archetype});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing icon
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    archetype.color.withValues(alpha: 0.25),
                    archetype.color.withValues(alpha: 0.08),
                    archetype.color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Text(
              archetype.icon,
              style: const TextStyle(fontSize: 64),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),

        const SizedBox(height: 16),

        // Archetype title
        Text(
          archetype.title,
          style: ZenithTheme.cormorant(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: archetype.color,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

        const SizedBox(height: 10),

        // Description
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            archetype.description,
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
              height: 1.5,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Radar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _RadarChartSection extends StatelessWidget {
  final Archetype archetype;
  final Map<String, int> domainTotals;

  const _RadarChartSection({
    required this.archetype,
    required this.domainTotals,
  });

  @override
  Widget build(BuildContext context) {
    final domains = Domain.all;
    final maxVal = domainTotals.values.fold<int>(0, (a, b) => math.max(a, b));
    final ceiling = maxVal > 0 ? maxVal.toDouble() : 100.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 280,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
            tickBorderData: BorderSide(
              color: ZenithColors.textMuted.withValues(alpha: 0.15),
              width: 0.5,
            ),
            gridBorderData: BorderSide(
              color: ZenithColors.textMuted.withValues(alpha: 0.12),
              width: 0.5,
            ),
            radarBorderData: BorderSide.none,
            titlePositionPercentageOffset: 0.2,
            titleTextStyle: ZenithTheme.dmSans(fontSize: 11, color: ZenithColors.textLight),
            getTitle: (index, _) {
              final domain = domains[index];
              return RadarChartTitle(
                text: '${domain.icon} ${domain.label}',
              );
            },
            dataSets: [
              RadarDataSet(
                fillColor: archetype.color.withValues(alpha: 0.3),
                borderColor: archetype.color.withValues(alpha: 0.8),
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: domains.map((d) {
                  final val = domainTotals[d.id]?.toDouble() ?? 0.0;
                  return RadarEntry(value: val.clamp(0, ceiling));
                }).toList(),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Sub-skills by Domain
// ─────────────────────────────────────────────────────────────────────────────

class _SubSkillsSection extends StatelessWidget {
  final Archetype archetype;
  final List<SubSkill> subSkills;

  const _SubSkillsSection({
    required this.archetype,
    required this.subSkills,
  });

  @override
  Widget build(BuildContext context) {
    // Group by domain
    final grouped = <String, List<SubSkill>>{};
    for (final skill in subSkills) {
      (grouped[skill.domain] ??= []).add(skill);
    }

    final domainEntries = Domain.all
        .where((d) => grouped.containsKey(d.id) && grouped[d.id]!.isNotEmpty)
        .toList();

    if (domainEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Complete tasks to unlock sub-skills',
          style: ZenithTheme.dmSans(fontSize: 14, color: ZenithColors.textMuted),
        ),
      );
    }

    int delayIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final domain in domainEntries) ...[
          // Domain header
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Row(
              children: [
                Text(domain.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  domain.label,
                  style: ZenithTheme.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: domain.color,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (300 + delayIndex * 60).ms)
              .slideX(begin: -0.05, duration: 400.ms),

          // Skills in domain
          for (final skill in grouped[domain.id]!) ...[
            _SubSkillRow(
              skill: skill,
              domainColor: domain.color,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: (340 + (delayIndex++) * 60).ms)
                .slideX(begin: -0.08, duration: 400.ms),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SubSkillRow extends StatelessWidget {
  final SubSkill skill;
  final Color domainColor;

  const _SubSkillRow({required this.skill, required this.domainColor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      child: Row(
        children: [
          // Skill icon
          Text(skill.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),

          // Skill name
          Expanded(
            child: Text(
              skill.name,
              style: ZenithTheme.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Level chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: domainColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lv.${skill.level}',
              style: ZenithTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: domainColor,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // XP progress bar
          SizedBox(
            width: 56,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: domainColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: skill.levelProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: domainColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Archetype Gallery
// ─────────────────────────────────────────────────────────────────────────────

class _ArchetypeGallery extends StatelessWidget {
  final Archetype currentArchetype;
  final Map<String, double> matchScores;

  const _ArchetypeGallery({
    required this.currentArchetype,
    required this.matchScores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            'ALL ARCHETYPES',
            style: ZenithTheme.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ZenithColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),

        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Archetype.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final arch = Archetype.all[index];
              final isActive = arch.id == currentArchetype.id;
              final score = matchScores[arch.id] ?? 0.0;
              final pct = (score * 100).round();

              return SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with optional ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? arch.color.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isActive ? arch.color : ZenithColors.cardBorder,
                          width: isActive ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(arch.icon, style: const TextStyle(fontSize: 32)),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Name
                    Text(
                      arch.name,
                      style: ZenithTheme.dmSans(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? arch.color : ZenithColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Match %
                    Text(
                      '$pct%',
                      style: ZenithTheme.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: pct > 30 ? ZenithColors.gold : ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}
