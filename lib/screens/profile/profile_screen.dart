import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/archetype.dart';
import '../../models/sub_skill.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/snackbar_helper.dart';
import '../onboarding/onboarding_flow.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final archetype = app.archetype;
        final subSkills = app.subSkills;
        final stats = app.stats;
        final domainTotals = stats.domainTotals(subSkills);
        final matchScores = Archetype.matchScores(domainTotals);

        return Scaffold(
          backgroundColor: ZenithColors.bg,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero: Archetype Image (chunked reveal) ──
                    _ArchetypeHero(archetype: archetype, app: app),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // ── Radar Chart ──
                      _RadarSection(
                        archetype: archetype,
                        domainTotals: domainTotals,
                      ),
                      const SizedBox(height: 24),

                      // ── Sub-Skills ──
                      _SubSkillsSection(
                        archetype: archetype,
                        subSkills: subSkills,
                      ),
                      const SizedBox(height: 24),

                      // ── Archetype Gallery ──
                      _ArchetypeGallery(
                        currentArchetype: archetype,
                        matchScores: matchScores,
                      ),
                      const SizedBox(height: 32),

                      // ── Settings ──
                      Text(
                        'Settings',
                        style: ZenithTheme.cormorant(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () =>
                            _openUrl('https://zenith-app.com/privacy'),
                      ),
                      const SizedBox(height: 8),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Terms & Conditions',
                        onTap: () =>
                            _openUrl('https://zenith-app.com/terms'),
                      ),
                      const SizedBox(height: 8),
                      _SettingsTile(
                        icon: Icons.refresh_rounded,
                        label: 'Reset Onboarding',
                        subtitle: 'Start the setup process again',
                        onTap: () =>
                            _confirmResetOnboarding(context, app),
                        danger: true,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Floating back button ──
          if (Navigator.of(context).canPop())
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmResetOnboarding(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Onboarding?',
          style: ZenithTheme.cormorant(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will reset your setup and take you back to the onboarding flow. '
          'Your existing data (stats, completions) will be kept, but you\'ll '
          'get a new programme.',
          style: ZenithTheme.dmSans(
            fontSize: 14,
            color: ZenithColors.textLight,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await app.resetOnboarding();
              if (!context.mounted) return;
              final error = app.consumeError();
              if (error != null) {
                showErrorSnackbar(context, error);
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingFlow()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: ZenithColors.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Archetype Hero — Large image with chunked reveal animation
// ═══════════════════════════════════════════════════════════════════════════

class _ArchetypeHero extends StatefulWidget {
  final Archetype archetype;
  final AppProvider app;

  const _ArchetypeHero({required this.archetype, required this.app});

  @override
  State<_ArchetypeHero> createState() => _ArchetypeHeroState();
}

class _ArchetypeHeroState extends State<_ArchetypeHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Grid dimensions for the chunked reveal
  static const _cols = 5;
  static const _rows = 6;

  // Pre-computed reveal order (randomized but deterministic per build)
  late final List<int> _revealOrder;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // Create a shuffled order for revealing chunks
    _revealOrder = List.generate(_cols * _rows, (i) => i);
    _revealOrder.shuffle(math.Random(42));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arch = widget.archetype;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 1.1; // tall hero

    return SizedBox(
      height: imageHeight + 80, // extra space for text overlay
      child: Stack(
        children: [
          // ── Chunked image reveal ──
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRect(
                child: SizedBox(
                  width: screenWidth,
                  height: imageHeight,
                  child: Stack(
                    children: [
                      // Background gradient while loading
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(arch.color, Colors.black, 0.7)!,
                              Color.lerp(arch.color, Colors.black, 0.9)!,
                            ],
                          ),
                        ),
                      ),

                      // Image chunks
                      for (int i = 0; i < _cols * _rows; i++)
                        _buildChunk(i, screenWidth, imageHeight, arch),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Top gradient for status bar legibility ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom gradient fade to bg ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ZenithColors.bg.withValues(alpha: 0.6),
                    ZenithColors.bg,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Text overlay at bottom ──
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arch.title,
                  style: ZenithTheme.cormorant(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: arch.color,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Level ${widget.app.stats.level}',
                      style: ZenithTheme.mono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ZenithColors.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: ZenithTheme.dmSans(
                        fontSize: 14,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.app.stats.totalXP} XP',
                      style: ZenithTheme.mono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ZenithColors.gold,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  arch.description,
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: ZenithColors.textLight,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChunk(int index, double width, double height, Archetype arch) {
    final col = index % _cols;
    final row = index ~/ _cols;
    final chunkW = width / _cols;
    final chunkH = height / _rows;

    // Each chunk reveals at a staggered time based on its position in the
    // shuffled reveal order. Total animation = 1.8s, each chunk gets ~60ms
    // of the timeline to appear.
    final orderIndex = _revealOrder.indexOf(index);
    final totalChunks = _cols * _rows;
    final chunkStart = (orderIndex / totalChunks) * 0.7; // first 70% of timeline
    final chunkEnd = chunkStart + 0.15; // each chunk takes 15% to fully appear

    final progress = _controller.value;
    final chunkOpacity =
        ((progress - chunkStart) / (chunkEnd - chunkStart)).clamp(0.0, 1.0);
    final chunkScale =
        0.6 + (0.4 * Curves.easeOut.transform(chunkOpacity));

    if (chunkOpacity <= 0) return const SizedBox.shrink();

    return Positioned(
      left: col * chunkW,
      top: row * chunkH,
      width: chunkW,
      height: chunkH,
      child: Opacity(
        opacity: chunkOpacity,
        child: Transform.scale(
          scale: chunkScale,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: width,
              maxHeight: height,
              alignment: Alignment(
                -1.0 + (2 * col / (_cols - 1)),
                -1.0 + (2 * row / (_rows - 1)),
              ),
              child: Image.asset(
                arch.imagePath,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: arch.color.withValues(alpha: 0.3),
                  child: Center(
                    child: Text(arch.icon,
                        style: const TextStyle(fontSize: 80)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Radar Chart Section
// ═══════════════════════════════════════════════════════════════════════════

class _RadarSection extends StatelessWidget {
  final Archetype archetype;
  final Map<String, int> domainTotals;

  const _RadarSection({
    required this.archetype,
    required this.domainTotals,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal =
        domainTotals.values.fold<int>(0, (a, b) => math.max(a, b));
    final ceiling = maxVal > 0 ? maxVal.toDouble() : 100.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 280,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle:
                const TextStyle(fontSize: 0, color: Colors.transparent),
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
            titleTextStyle: ZenithTheme.dmSans(
                fontSize: 11, color: ZenithColors.textLight),
            getTitle: (index, _) {
              final d = Domain.all[index];
              return RadarChartTitle(text: '${d.icon} ${d.label}');
            },
            dataSets: [
              RadarDataSet(
                fillColor: archetype.color.withValues(alpha: 0.3),
                borderColor: archetype.color.withValues(alpha: 0.8),
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: Domain.all.map((d) {
                  final val = domainTotals[d.id]?.toDouble() ?? 0.0;
                  return RadarEntry(value: val.clamp(0, ceiling));
                }).toList(),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 600),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-Skills by Domain
// ═══════════════════════════════════════════════════════════════════════════

class _SubSkillsSection extends StatelessWidget {
  final Archetype archetype;
  final List<SubSkill> subSkills;

  const _SubSkillsSection({
    required this.archetype,
    required this.subSkills,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SubSkill>>{};
    for (final skill in subSkills) {
      (grouped[skill.domain] ??= []).add(skill);
    }

    final domainEntries = Domain.all
        .where((d) =>
            grouped.containsKey(d.id) && grouped[d.id]!.isNotEmpty)
        .toList();

    if (domainEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Complete tasks to unlock sub-skills',
          style: ZenithTheme.dmSans(
              fontSize: 14, color: ZenithColors.textMuted),
        ),
      );
    }

    int delayIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR SKILLS',
          style: ZenithTheme.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ZenithColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        for (final domain in domainEntries) ...[
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
              .fadeIn(
                  duration: 400.ms,
                  delay: (500 + delayIndex * 60).ms)
              .slideX(begin: -0.05, duration: 400.ms),
          for (final skill in grouped[domain.id]!) ...[
            _SubSkillRow(skill: skill, domainColor: domain.color)
                .animate()
                .fadeIn(
                    duration: 400.ms,
                    delay: (540 + (delayIndex++) * 60).ms)
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
          Text(skill.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              skill.name,
              style: ZenithTheme.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ═══════════════════════════════════════════════════════════════════════════
// Archetype Gallery
// ═══════════════════════════════════════════════════════════════════════════

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
        Text(
          'ALL ARCHETYPES',
          style: ZenithTheme.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ZenithColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Archetype.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final arch = Archetype.all[index];
              final isActive = arch.id == currentArchetype.id;
              final score = matchScores[arch.id] ?? 0.0;
              final pct = (score * 100).round();

              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(arch.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                arch.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            arch.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          if (arch.activities.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              arch.activities,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      backgroundColor: Color.lerp(
                          arch.color, Colors.black, 0.5),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tarot card thumbnail
                      Container(
                        width: 64,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? arch.color
                                : ZenithColors.cardBorder,
                            width: isActive ? 2.5 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color:
                                        arch.color.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            arch.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: arch.color.withValues(alpha: 0.1),
                              child: Center(
                                child: Text(arch.icon,
                                    style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        arch.name,
                        style: ZenithTheme.dmSans(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? arch.color
                              : ZenithColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$pct%',
                        style: ZenithTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: pct > 30
                              ? ZenithColors.gold
                              : ZenithColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Settings Tile
// ═══════════════════════════════════════════════════════════════════════════

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? ZenithColors.danger : ZenithColors.text;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color:
                  danger ? ZenithColors.danger : ZenithColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ZenithTheme.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: ZenithTheme.dmSans(
                      fontSize: 12,
                      color: ZenithColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: ZenithColors.textMuted),
        ],
      ),
    );
  }
}
