import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/archetype.dart';
import '../../../models/habit.dart';
import '../../../models/programme.dart';
import '../../../models/sub_skill.dart';
import '../../../theme.dart';
import '../../../widgets/glass_card.dart';

class ValueDeliveryScreen extends StatelessWidget {
  final Programme? programme;
  final List<Habit> habits;
  final List<SubSkill> subSkills;
  final Archetype archetype;
  final VoidCallback onNext;

  const ValueDeliveryScreen({
    super.key,
    required this.programme,
    required this.habits,
    this.subSkills = const [],
    required this.archetype,
    required this.onNext,
  });

  String _habitTypeIcon(HabitType type) {
    switch (type) {
      case HabitType.checkbox:
        return '\u2705';
      case HabitType.abstinence:
        return '\u26D4';
      case HabitType.timed:
        return '\u23F1';
      case HabitType.counter:
        return '\uD83D\uDD22';
    }
  }

  String _habitDetail(Habit h) {
    if (h.type == HabitType.timed && h.targetValue != null) {
      return '${h.targetValue} ${h.unit ?? 'min'}';
    }
    if (h.type == HabitType.counter && h.targetValue != null) {
      return '${h.targetValue} ${h.unit ?? 'reps'}';
    }
    if (h.type == HabitType.abstinence) return 'Abstinence';
    return 'Daily';
  }

  String _subSkillLabel(String subSkillId) {
    final skill = subSkills.where((s) => s.id == subSkillId).firstOrNull;
    if (skill != null) return skill.name;
    // Fallback: format the id nicely
    return subSkillId.replaceAll('_', ' ').replaceFirstMapped(
        RegExp(r'^.'), (m) => m[0]!.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              // Header
              Text(
                'Your Day 1 is ready',
                style: ZenithTheme.cormorant(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 500.ms),

              if (programme != null) ...[
                const SizedBox(height: 12),

                // Programme name + description card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  color: ZenithColors.primary.withValues(alpha: 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: ZenithColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            programme!.name,
                            style: ZenithTheme.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ZenithColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (programme!.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          programme!.description,
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (programme!.coachingNote.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('\u{1F4AC}',
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  programme!.coachingNote,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 13,
                                    color: ZenithColors.text,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              ],

              const SizedBox(height: 24),

              // Section: Daily habits
              Text(
                'YOUR DAILY HABITS',
                style: ZenithTheme.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: ZenithColors.textMuted,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 12),

              ...List.generate(habits.length, (i) {
                final h = habits[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          _habitTypeIcon(h.type),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: ZenithTheme.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _Tag(_habitDetail(h)),
                                  const SizedBox(width: 6),
                                  _Tag(_subSkillLabel(h.subSkillId)),
                                  const SizedBox(width: 6),
                                  _Tag('${h.baseXP} XP'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                      delay: (500 + i * 100).ms,
                      duration: 400.ms,
                    );
              }),

              const SizedBox(height: 20),

              // Archetype card
              GlassCard(
                padding: const EdgeInsets.all(20),
                color: ZenithColors.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Text(
                      archetype.icon,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting archetype',
                            style: ZenithTheme.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: ZenithColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            archetype.title,
                            style: ZenithTheme.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ZenithColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete habits to evolve your archetype over 30 days',
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              color: ZenithColors.textLight,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    delay: 900.ms,
                    duration: 500.ms,
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Start my journey'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ZenithColors.primaryPale.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: ZenithTheme.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ZenithColors.primary,
        ),
      ),
    );
  }
}
