import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/stat_snapshot.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';

class ProgrammeScreen extends StatelessWidget {
  const ProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final programme = app.programme;
        if (programme == null) {
          return Scaffold(
            backgroundColor: ZenithColors.bg,
            body: Center(
              child: Text(
                'No active programme',
                style: ZenithTheme.dmSans(color: ZenithColors.textLight),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: ZenithColors.bg,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          programme.name,
                          style: ZenithTheme.cormorant(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 4),
                        Text(
                          programme.theme,
                          style: ZenithTheme.dmSans(
                            fontSize: 14,
                            color: ZenithColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          programme.description,
                          style: ZenithTheme.dmSans(
                            fontSize: 14,
                            color: ZenithColors.textLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progress bar
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Day ${programme.currentDay} of 30',
                                    style: ZenithTheme.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${(programme.progressPercent * 100).toInt()}%',
                                    style: ZenithTheme.mono(
                                      fontSize: 14,
                                      color: ZenithColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: programme.progressPercent,
                                  minHeight: 8,
                                  backgroundColor: ZenithColors.primaryPale
                                      .withValues(alpha: 0.3),
                                  color: ZenithColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 30-day calendar grid
                        Text(
                          'Journey Map',
                          style: ZenithTheme.cormorant(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DayGrid(currentDay: programme.currentDay),
                        const SizedBox(height: 24),

                        // Quests
                        Text(
                          'Active Quests',
                          style: ZenithTheme.cormorant(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...app.quests.map((quest) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          StatSnapshot.statIcons[
                                                  quest.primaryStat] ??
                                              '',
                                          style:
                                              const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            quest.title,
                                            style: ZenithTheme.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      quest.description,
                                      style: ZenithTheme.dmSans(
                                        fontSize: 13,
                                        color: ZenithColors.textLight,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Phase progress
                                    if (quest.phases.isNotEmpty) ...[
                                      Row(
                                        children: quest.phases
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final isComplete =
                                              entry.value.completed;
                                          final isCurrent =
                                              entry.key ==
                                                  quest.currentPhase;
                                          return Expanded(
                                            child: Container(
                                              height: 4,
                                              margin: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 2),
                                              decoration: BoxDecoration(
                                                color: isComplete
                                                    ? ZenithColors.primary
                                                    : isCurrent
                                                        ? ZenithColors
                                                            .primaryLight
                                                        : ZenithColors
                                                            .primaryPale
                                                            .withValues(
                                                                alpha:
                                                                    0.3),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        2),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Phase ${quest.currentPhase + 1}: ${quest.phases[quest.currentPhase].name}',
                                        style: ZenithTheme.dmSans(
                                          fontSize: 12,
                                          color: ZenithColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )),

                        const SizedBox(height: 24),

                        // Habits overview
                        Text(
                          'Programme Habits',
                          style: ZenithTheme.cormorant(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...app.habits.map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      StatSnapshot.statIcons[
                                              habit.primaryStat] ??
                                          '',
                                      style:
                                          const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit.name,
                                            style: ZenithTheme.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${habit.typeLabel} | +${habit.baseXP} XP',
                                            style: ZenithTheme.dmSans(
                                              fontSize: 12,
                                              color:
                                                  ZenithColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 24),

                        // Coaching note
                        if (programme.coachingNote.isNotEmpty)
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            color: ZenithColors.primary
                                .withValues(alpha: 0.06),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: ZenithColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Coach\'s Note',
                                      style: ZenithTheme.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ZenithColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  programme.coachingNote,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 14,
                                    color: ZenithColors.textLight,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayGrid extends StatelessWidget {
  final int currentDay;
  const _DayGrid({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(30, (i) {
          final day = i + 1;
          final isPast = day < currentDay;
          final isToday = day == currentDay;
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isToday
                  ? ZenithColors.primary
                  : isPast
                      ? ZenithColors.primary.withValues(alpha: 0.15)
                      : ZenithColors.bgDark,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? null
                  : Border.all(
                      color: isPast
                          ? ZenithColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: ZenithTheme.dmSans(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday
                    ? Colors.white
                    : isPast
                        ? ZenithColors.primary
                        : ZenithColors.textMuted,
              ),
            ),
          );
        }),
      ),
    );
  }
}
