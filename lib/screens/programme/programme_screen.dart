import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../models/programme.dart';
import '../../models/quest.dart';
import '../../models/sub_skill.dart';
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

        SubSkill? findSubSkill(String id) =>
            app.subSkills.where((s) => s.id == id).firstOrNull;

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
                                          findSubSkill(quest.subSkillId)?.icon ??
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
                                      findSubSkill(habit.subSkillId)?.icon ??
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
                // ── Past Programmes ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'Past Programmes',
                      style: ZenithTheme.cormorant(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _PastProgrammes(app: app),
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

// ── Past Programmes Section ──

class _PastProgrammes extends StatefulWidget {
  final AppProvider app;
  const _PastProgrammes({required this.app});

  @override
  State<_PastProgrammes> createState() => _PastProgrammesState();
}

class _PastProgrammesState extends State<_PastProgrammes> {
  List<Programme>? _pastProgrammes;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final programmes = await widget.app.getPastProgrammes();
    if (mounted) setState(() => _pastProgrammes = programmes);
  }

  String _formatDateRange(Programme p) {
    final start = '${p.startDate.day}/${p.startDate.month}/${p.startDate.year}';
    final end = '${p.endDate.day}/${p.endDate.month}/${p.endDate.year}';
    return '$start — $end';
  }

  @override
  Widget build(BuildContext context) {
    if (_pastProgrammes == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ZenithColors.primary,
            ),
          ),
        ),
      );
    }

    if (_pastProgrammes!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Complete your first programme to see it here.',
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _pastProgrammes!.map((p) {
          final isExpanded = _expandedId == p.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() =>
                  _expandedId = isExpanded ? null : p.id),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: ZenithTheme.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateRange(p),
                                style: ZenithTheme.dmSans(
                                  fontSize: 12,
                                  color: ZenithColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: ZenithColors.textMuted,
                        ),
                      ],
                    ),
                    if (p.focusPillars.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: p.focusPillars
                            .map((pillar) => Chip(
                                  label: Text(pillar),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      Text(
                        p.theme,
                        style: ZenithTheme.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ZenithColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.description,
                        style: ZenithTheme.dmSans(
                          fontSize: 13,
                          color: ZenithColors.textLight,
                          height: 1.5,
                        ),
                      ),
                      if (p.coachingNote.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          p.coachingNote,
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _PastProgrammeDetails(
                        app: widget.app,
                        programmeId: p.id,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PastProgrammeDetails extends StatefulWidget {
  final AppProvider app;
  final String programmeId;
  const _PastProgrammeDetails({
    required this.app,
    required this.programmeId,
  });

  @override
  State<_PastProgrammeDetails> createState() =>
      _PastProgrammeDetailsState();
}

class _PastProgrammeDetailsState extends State<_PastProgrammeDetails> {
  List<Habit>? _habits;
  List<Quest>? _quests;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits =
        await widget.app.getHabitsForProgramme(widget.programmeId);
    final quests =
        await widget.app.getQuestsForProgramme(widget.programmeId);
    if (mounted) {
      setState(() {
        _habits = habits;
        _quests = quests;
      });
    }
  }

  SubSkill? _findSubSkill(String id) =>
      widget.app.subSkills.where((s) => s.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    if (_habits == null) {
      return const SizedBox(
        height: 30,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quests != null && _quests!.isNotEmpty) ...[
          Text(
            'Quests',
            style: ZenithTheme.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ZenithColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ..._quests!.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      _findSubSkill(q.subSkillId)?.icon ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.title,
                        style: ZenithTheme.dmSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
        ],
        if (_habits!.isNotEmpty) ...[
          Text(
            'Habits',
            style: ZenithTheme.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ZenithColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ..._habits!.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      _findSubSkill(h.subSkillId)?.icon ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h.name,
                        style: ZenithTheme.dmSans(fontSize: 13),
                      ),
                    ),
                    Text(
                      '+${h.baseXP} XP',
                      style: ZenithTheme.mono(
                        fontSize: 11,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
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
