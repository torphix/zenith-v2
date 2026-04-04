import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/archetype.dart';
import '../../models/stat_snapshot.dart';
import '../../models/wrap_data.dart';
import '../../theme.dart';

class WeeklyWrapScreen extends StatefulWidget {
  final WrapData wrap;
  final List<WrapData> dailyWraps;

  const WeeklyWrapScreen({
    super.key,
    required this.wrap,
    required this.dailyWraps,
  });

  @override
  State<WeeklyWrapScreen> createState() => _WeeklyWrapScreenState();
}

class _WeeklyWrapScreenState extends State<WeeklyWrapScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final wrap = widget.wrap;
    final archetype = Archetype.all.firstWhere(
      (a) => a.id == wrap.archetypeId,
      orElse: () => Archetype.all.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              HapticFeedback.selectionClick();
            },
            children: [
              // Page 1: Weekly Overview
              _GradientPage(
                colors: [const Color(0xFF16213E), const Color(0xFF0F3460)],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'WEEKLY WRAP',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '${(wrap.completionRate * 100).toInt()}%',
                      style: ZenithTheme.mono(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.6, 0.6)),
                    Text(
                      'avg completion',
                      style: ZenithTheme.cormorant(
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WrapStat(
                          label: 'Total XP',
                          value: '+${wrap.totalXP}',
                          color: ZenithColors.gold,
                        ),
                        const SizedBox(width: 32),
                        _WrapStat(
                          label: 'Habits Done',
                          value: '${wrap.habitsCompleted}',
                          color: ZenithColors.mint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Page 2: Daily trend
              _GradientPage(
                colors: [const Color(0xFF2D2B55), const Color(0xFF4B3F72)],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DAILY TREND',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 200,
                      child: _WeekChart(dailyWraps: widget.dailyWraps),
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 24),
                    // Completion dots for each day
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.dailyWraps.asMap().entries.map((e) {
                        final rate = e.value.completionRate;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: rate >= 0.8
                                ? ZenithColors.primary
                                : rate >= 0.5
                                    ? ZenithColors.primaryLight
                                        .withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${e.key + 1}',
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Page 3: Skills
              _GradientPage(
                colors: [
                  Color.lerp(archetype.color, Colors.black, 0.7)!,
                  Color.lerp(archetype.color, Colors.black, 0.4)!,
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SKILLS LEVELED',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...wrap.statsGained.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              StatSnapshot.statIcons[entry.key] ?? '',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  StatSnapshot.statLabels[entry.key] ??
                                      entry.key,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '+${entry.value} XP this week',
                                  style: ZenithTheme.dmSans(
                                    fontSize: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                            delay: (200 +
                                    wrap.statsGained.keys
                                            .toList()
                                            .indexOf(entry.key) *
                                        150)
                                .ms,
                          );
                    }),
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
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
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ],
          ),

          // Page indicators
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Close
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPage extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  const _GradientPage({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: child,
        ),
      ),
    );
  }
}

class _WrapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WrapStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: ZenithTheme.mono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
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

class _WeekChart extends StatelessWidget {
  final List<WrapData> dailyWraps;
  const _WeekChart({required this.dailyWraps});

  @override
  Widget build(BuildContext context) {
    if (dailyWraps.isEmpty) {
      return Center(
        child: Text(
          'No data yet',
          style: ZenithTheme.dmSans(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: dailyWraps.asMap().entries.map((e) {
              return FlSpot(
                  e.key.toDouble(), e.value.completionRate * 100);
            }).toList(),
            isCurved: true,
            color: ZenithColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: ZenithColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ZenithColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }
}
