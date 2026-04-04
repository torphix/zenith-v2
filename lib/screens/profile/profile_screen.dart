import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/stat_snapshot.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return Scaffold(
          backgroundColor: ZenithColors.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: ZenithTheme.cormorant(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              ZenithColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            (app.profile?.name ?? 'S')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: ZenithTheme.cormorant(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: ZenithColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.profile?.name ?? 'Seeker',
                                style: ZenithTheme.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Level ${app.stats.level} | ${app.stats.totalXP} XP',
                                style: ZenithTheme.dmSans(
                                  fontSize: 13,
                                  color: ZenithColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),

                  // XP Progress bar
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level ${app.stats.level}',
                              style: ZenithTheme.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Level ${app.stats.level + 1}',
                              style: ZenithTheme.dmSans(
                                fontSize: 14,
                                color: ZenithColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: app.stats.levelProgress,
                            minHeight: 8,
                            backgroundColor:
                                ZenithColors.primaryPale.withValues(alpha: 0.3),
                            color: ZenithColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${app.stats.totalXP} / ${StatSnapshot.xpForLevel(app.stats.level + 1)} XP',
                          style: ZenithTheme.dmSans(
                            fontSize: 12,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Archetype
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    color: app.archetype.color.withValues(alpha: 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              app.archetype.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.archetype.title,
                                  style: ZenithTheme.cormorant(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: app.archetype.color,
                                  ),
                                ),
                                Text(
                                  'Your current archetype',
                                  style: ZenithTheme.dmSans(
                                    fontSize: 12,
                                    color: ZenithColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          app.archetype.description,
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 20),

                  // Stat Radar
                  Text(
                    'Character Stats',
                    style: ZenithTheme.cormorant(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 250,
                      child: _StatRadar(stats: app.stats.stats),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 20),

                  // Stats breakdown
                  ...StatSnapshot.statNames.map((stat) {
                    final value = app.stats.stats[stat] ?? 0;
                    final statMax = app.stats.stats.values.isEmpty
                        ? 1
                        : app.stats.stats.values
                            .reduce((a, b) => a > b ? a : b)
                            .clamp(1, 9999);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              StatSnapshot.statIcons[stat] ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    StatSnapshot.statLabels[stat] ?? stat,
                                    style: ZenithTheme.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value:
                                          statMax == 0 ? 0 : value / statMax,
                                      minHeight: 4,
                                      backgroundColor: ZenithColors
                                          .primaryPale
                                          .withValues(alpha: 0.3),
                                      color: ZenithColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$value',
                              style: ZenithTheme.mono(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ZenithColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Quick stats
                  Row(
                    children: [
                      _MiniStat(
                        label: 'Streak',
                        value: '${app.stats.currentStreak}',
                        icon: Icons.local_fire_department_rounded,
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'Best Streak',
                        value: '${app.stats.longestStreak}',
                        icon: Icons.emoji_events_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: ZenithColors.gold),
            const SizedBox(height: 8),
            Text(
              value,
              style: ZenithTheme.mono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ZenithColors.primary,
              ),
            ),
            Text(
              label,
              style: ZenithTheme.dmSans(
                fontSize: 12,
                color: ZenithColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRadar extends StatelessWidget {
  final Map<String, int> stats;

  const _StatRadar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = StatSnapshot.statNames
        .map((s) => RadarEntry(value: (stats[s] ?? 0).toDouble()))
        .toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: ZenithColors.primary.withValues(alpha: 0.15),
            borderColor: ZenithColors.primary,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: entries,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: ZenithColors.primaryPale.withValues(alpha: 0.3),
        ),
        gridBorderData: BorderSide(
          color: ZenithColors.primaryPale.withValues(alpha: 0.2),
        ),
        tickCount: 4,
        tickBorderData: BorderSide(
          color: ZenithColors.primaryPale.withValues(alpha: 0.15),
        ),
        ticksTextStyle: const TextStyle(fontSize: 0),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, _) {
          final name = StatSnapshot.statNames[index];
          return RadarChartTitle(
            text:
                '${StatSnapshot.statIcons[name]} ${StatSnapshot.statLabels[name]}',
            angle: 0,
          );
        },
        radarShape: RadarShape.polygon,
      ),
    );
  }
}
