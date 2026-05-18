import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/completion.dart';
import '../models/habit.dart';
import '../models/programme.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'glass_card.dart';

class JourneyCalendar extends StatefulWidget {
  final Programme programme;
  final AppProvider app;

  const JourneyCalendar({
    super.key,
    required this.programme,
    required this.app,
  });

  @override
  State<JourneyCalendar> createState() => _JourneyCalendarState();
}

class _JourneyCalendarState extends State<JourneyCalendar> {
  bool _expanded = false;
  int? _selectedDay;
  List<Completion>? _selectedDayCompletions;
  bool _loadingCompletions = false;

  Programme get programme => widget.programme;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // ── Collapsed header (always visible) ──
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expanded = !_expanded;
                  if (!_expanded) {
                    _selectedDay = null;
                    _selectedDayCompletions = null;
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ZenithColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: ZenithColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day ${programme.currentDay} of 30',
                                style: ZenithTheme.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                today,
                                style: ZenithTheme.dmSans(
                                  fontSize: 12,
                                  color: ZenithColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: programme.progressPercent,
                        minHeight: 4,
                        backgroundColor:
                            ZenithColors.primaryPale.withValues(alpha: 0.2),
                        color: ZenithColors.primary,
                      ),
                    ),
                    SizedBox(height: _expanded ? 4 : 14),
                  ],
                ),
              ),
            ),

            // ── Expanded: 30-day grid ──
            if (_expanded) ...[
              Divider(height: 1, color: ZenithColors.cardBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programme.name,
                      style: ZenithTheme.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenithColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDayGrid(),
                  ],
                ),
              ),

              // ── Selected day detail ──
              if (_selectedDay != null) _buildDayDetail(),

              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayGrid() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(30, (i) {
        final dayNum = i + 1;
        final isToday = dayNum == programme.currentDay;
        final isPast = dayNum < programme.currentDay;
        final isSelected = dayNum == _selectedDay;

        return GestureDetector(
          onTap: isPast || isToday
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDay = dayNum);
                  _loadDayCompletions(dayNum);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 56 - 12 - 30) / 6,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? ZenithColors.primary
                  : isToday
                      ? ZenithColors.primary.withValues(alpha: 0.15)
                      : isPast
                          ? ZenithColors.primaryPale.withValues(alpha: 0.2)
                          : ZenithColors.bgMid.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(
                      color: ZenithColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: ZenithTheme.dmSans(
                fontSize: 13,
                fontWeight:
                    isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? ZenithColors.primary
                        : isPast
                            ? ZenithColors.text
                            : ZenithColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayDetail() {
    final dayDate = programme.startDate.add(Duration(days: _selectedDay! - 1));
    final dateStr = DateFormat('EEEE, d MMMM').format(dayDate);
    final habits = widget.app.habits;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZenithColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ZenithColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day $_selectedDay',
                style: ZenithTheme.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                dateStr,
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  color: ZenithColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingCompletions)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: ZenithColors.primary,
                  ),
                ),
              ),
            )
          else if (_selectedDayCompletions != null) ...[
            // Completion rate
            _buildCompletionSummary(habits),
            const SizedBox(height: 8),
            // Habit list
            ..._buildHabitList(habits),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildCompletionSummary(List<Habit> habits) {
    final completed =
        _selectedDayCompletions!.where((c) => c.completed).length;
    final total = habits.length;
    final rate = total > 0 ? completed / total : 0.0;
    final xp = _selectedDayCompletions!.fold(0, (s, c) => s + c.xpEarned);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 4,
              backgroundColor: ZenithColors.primaryPale.withValues(alpha: 0.2),
              color: ZenithColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$completed/$total',
          style: ZenithTheme.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ZenithColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '+$xp XP',
          style: ZenithTheme.dmSans(
            fontSize: 11,
            color: ZenithColors.textMuted,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHabitList(List<Habit> habits) {
    final completedIds =
        _selectedDayCompletions!.where((c) => c.completed).map((c) => c.habitId).toSet();

    return habits.map((h) {
      final done = completedIds.contains(h.id);
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: done ? ZenithColors.primary : ZenithColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                h.name,
                style: ZenithTheme.dmSans(
                  fontSize: 13,
                  color: done ? ZenithColors.text : ZenithColors.textMuted,
                ).copyWith(
                  decoration:
                      done ? TextDecoration.none : TextDecoration.lineThrough,
                  decorationColor: ZenithColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _loadDayCompletions(int dayNum) async {
    setState(() => _loadingCompletions = true);
    final date = programme.startDate.add(Duration(days: dayNum - 1));
    final completions = await widget.app.getCompletionsForDay(date);
    if (!mounted) return;
    setState(() {
      _selectedDayCompletions = completions;
      _loadingCompletions = false;
    });
  }
}
