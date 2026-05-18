import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../models/adhoc_task.dart';
import '../../models/archetype.dart';
import '../../models/completion.dart';
import '../../models/habit.dart';
import '../../models/programme.dart';
import '../../models/stat_snapshot.dart';
import '../../models/sub_skill.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/journey_calendar.dart';
import '../../widgets/snackbar_helper.dart';

import '../coach/coach_screen.dart';
import '../wraps/epic_wrap_screen.dart';
import 'timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        if (app.isLoading) {
          return Scaffold(
            backgroundColor: ZenithColors.bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: ZenithColors.primary.withValues(alpha: 0.4),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your programme...',
                    style: ZenithTheme.dmSans(
                      fontSize: 14,
                      color: ZenithColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _HomeBody(app: app);
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  final AppProvider app;
  const _HomeBody({required this.app});

  @override
  Widget build(BuildContext context) {
    final programme = app.programme;

    return Scaffold(
      backgroundColor: ZenithColors.bg,
      floatingActionButton: _AddActionFAB(app: app),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.refreshTodayData,
          child: CustomScrollView(
            slivers: [
              // ── Welcome ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _welcomeMessage(app.profile?.name),
                        style: ZenithTheme.cormorant(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (programme != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Day ${programme.currentDay} of 30',
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Calendar ──
              if (programme != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: JourneyCalendar(
                      programme: programme,
                      app: app,
                    ),
                  ),
                ),
              if (programme != null)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Action Strip (horizontal scroll) ──
              SliverToBoxAdapter(
                child: _ActionStrip(app: app, programme: programme),
              ),

              // ── Swipeable Graphics (Clock Wheel + Skills Radar) ──
              if (app.habits.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _SwipeableGraphics(
                      habits: app.habits,
                      completions: app.todayCompletions,
                      adhocTasks: app.todayAdhocTasks,
                      totalMinutesInvested: app.todayMinutesInvested,
                      subSkills: app.subSkills,
                      stats: app.stats,
                      archetype: app.archetype,
                    ),
                  ),
                ),
              if (app.habits.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Processing voice note (at top) ──
              if (app.isProcessingVoiceNote)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ZenithColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing your voice note...',
                            style: ZenithTheme.dmSans(
                              fontSize: 14,
                              color: ZenithColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Today's Tasks (habits + voice-logged combined) ──
              if (app.habits.isNotEmpty || app.todayAdhocTasks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'Today\'s Tasks',
                      style: ZenithTheme.cormorant(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (app.habits.isNotEmpty || app.todayAdhocTasks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Habits first, then adhoc tasks
                        if (index < app.habits.length) {
                          final habit = app.habits[index];
                          final isCompleted = app.isHabitCompleted(habit.id);
                          final completion =
                              app.getCompletionForHabit(habit.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HabitCard(
                              habit: habit,
                              isCompleted: isCompleted,
                              minutesSpent: completion?.value,
                              mediaPath: completion?.photoUrl,
                              mediaType: completion?.mediaType,
                              onTap: () => _showHabitSheet(
                                  context, app, habit, isCompleted, completion?.value),
                              onMedia: () => _pickMedia(context, app, habit),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: (100 * index).ms,
                                duration: 300.ms,
                              )
                              .slideX(begin: 0.05, end: 0);
                        } else {
                          final task = app.todayAdhocTasks[index - app.habits.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AdhocTaskCard(
                              task: task,
                              onToggle: () => app.toggleAdhocTask(task),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: (100 * index).ms,
                                duration: 300.ms,
                              )
                              .slideX(begin: 0.05, end: 0);
                        }
                      },
                      childCount: app.habits.length + app.todayAdhocTasks.length,
                    ),
                  ),
                ),

              // ── Empty state ──
              if (app.habits.isEmpty && app.todayAdhocTasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.mic_rounded,
                              size: 48, color: ZenithColors.primaryPale),
                          const SizedBox(height: 16),
                          Text(
                            'Record what you\'ve been up to',
                            style: ZenithTheme.cormorant(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the mic button to log tasks with your voice. '
                            'Your AI coach will turn them into trackable tasks.',
                            textAlign: TextAlign.center,
                            style: ZenithTheme.dmSans(
                              fontSize: 14,
                              color: ZenithColors.textLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Habit bottom sheet ──

  void _showHabitSheet(BuildContext context, AppProvider app, Habit habit,
      bool isCompleted, int? minutesSpent) {
    if (isCompleted) {
      final completion = app.getCompletionForHabit(habit.id);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CompletedHabitSheet(
          habit: habit,
          completion: completion,
          minutesSpent: minutesSpent,
          onUndo: () {
            app.toggleHabit(habit);
            Navigator.pop(context);
          },
          onTimeUpdated: (start, end) {
            app.updateCompletionTime(habit.id, start, end);
            Navigator.pop(context);
          },
        ),
      );
      return;
    }

    // Not completed — show timer / mark complete options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HabitActionSheet(
        habit: habit,
        onStartTimer: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TimerScreen(habit: habit, app: app),
            ),
          );
        },
        onComplete: (minutes) {
          app.completeHabitWithDuration(habit, minutes);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickMedia(BuildContext context, AppProvider app, Habit habit) {
    final storage = StorageService();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ZenithColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add proof',
                  style: ZenithTheme.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text('Take Photo',
                    style: ZenithTheme.dmSans(fontSize: 15)),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await storage.pickPhoto();
                  if (file != null) {
                    await app.addCompletionMedia(
                        habit.id, File(file.path), 'photo');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded),
                title: Text('Record Video',
                    style: ZenithTheme.dmSans(fontSize: 15)),
                subtitle: Text('Up to 30 seconds',
                    style: ZenithTheme.dmSans(
                        fontSize: 12, color: ZenithColors.textMuted)),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await storage.pickVideo();
                  if (file != null) {
                    await app.addCompletionMedia(
                        habit.id, File(file.path), 'video');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text('Choose from Gallery',
                    style: ZenithTheme.dmSans(fontSize: 15)),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await storage.pickFromGallery();
                  if (file != null) {
                    await app.addCompletionMedia(
                        habit.id, File(file.path), 'photo');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _welcomeMessage(String? name) {
    final hour = DateTime.now().hour;
    final n = name ?? 'Seeker';
    if (hour < 12) return 'Good morning, $n';
    if (hour < 17) return 'Good afternoon, $n';
    return 'Good evening, $n';
  }
}

// ══════════════════════════════════════════════
// ── Action Strip (horizontal scrollable actions) ──
// ══════════════════════════════════════════════

class _ActionStrip extends StatelessWidget {
  final AppProvider app;
  final Programme? programme;
  const _ActionStrip({required this.app, this.programme});

  String get _journalType => DateTime.now().hour < 12 ? 'morning' : 'evening';

  String get _journalPrompt {
    final hour = DateTime.now().hour;
    final habits = app.habits;
    final completions = app.todayCompletions;
    final done = completions.where((c) => c.completed).toList();
    final doneIds = done.map((c) => c.habitId).toSet();
    final doneNames = habits
        .where((h) => doneIds.contains(h.id))
        .map((h) => h.name)
        .toList();
    final pendingNames = habits
        .where((h) => !doneIds.contains(h.id))
        .map((h) => h.name)
        .toList();
    final streak = app.stats.currentStreak;
    final mins = app.todayMinutesInvested;
    final day = programme?.currentDay;
    final progName = programme?.name;

    if (hour < 12) {
      final parts = <String>[];
      if (day != null && progName != null) parts.add('Today is day $day of $progName.');
      if (streak > 1) parts.add("I'm on a $streak-day streak.");
      if (habits.isNotEmpty) parts.add('My habits for today: ${habits.map((h) => h.name).join(', ')}.');
      parts.add('Help me set a strong intention for today.');
      return parts.join(' ');
    }

    if (hour >= 17) {
      final pct = (app.todayCompletionRate * 100).round();
      final parts = <String>[];
      parts.add('I completed ${done.length} of ${habits.length} habits today ($pct%)');
      if (mins > 0) parts[0] += ', investing $mins minutes';
      parts[0] += '.';
      if (doneNames.isNotEmpty) parts.add('Completed: ${doneNames.join(', ')}.');
      if (pendingNames.isNotEmpty) parts.add('Still pending: ${pendingNames.join(', ')}.');
      if (streak > 1) parts.add('My streak is $streak days.');
      parts.add("Let's reflect on how today went.");
      return parts.join(' ');
    }

    // Midday
    final parts = <String>[];
    parts.add('Midday check-in: ${done.length} of ${habits.length} habits done so far');
    if (mins > 0) parts[0] += ', $mins minutes invested';
    parts[0] += '.';
    if (doneNames.isNotEmpty) parts.add('Done: ${doneNames.join(', ')}.');
    if (pendingNames.isNotEmpty) parts.add('Still to go: ${pendingNames.join(', ')}.');
    parts.add('How am I tracking?');
    return parts.join(' ');
  }

  bool get _shouldShowJournal {
    final hour = DateTime.now().hour;
    if (hour < 12) return !app.hasJournaledToday('morning');
    if (hour >= 17) return !app.hasJournaledToday('evening');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionCardData>[];

    // Daily / Weekly Wrap (priority)
    if (app.todayCompletionRate > 0 && programme != null) {
      final isWeekly = programme!.currentDay % 7 == 0;
      actions.add(_ActionCardData(
        icon: isWeekly
            ? Icons.calendar_view_week_rounded
            : Icons.auto_awesome_rounded,
        label: isWeekly ? 'Weekly Wrap' : 'Daily Wrap',
        subtitle: isWeekly ? "This week's highlights" : 'See your progress',
        color: ZenithColors.primary,
        onTap: () async {
          final wrap = isWeekly
              ? await app.generateWeeklyWrap()
              : await app.generateDailyWrap();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EpicWrapScreen(
                wrap: wrap,
                subSkills: app.subSkills,
              ),
            ),
          );
        },
      ));
    }

    // Journal / Reflection → opens coach with AI prompt
    if (_shouldShowJournal) {
      final isMorning = _journalType == 'morning';
      actions.add(_ActionCardData(
        icon: isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
        label: isMorning ? 'Morning Reflection' : 'Evening Reflection',
        subtitle: isMorning ? 'Set your intention' : 'Reflect on your day',
        color: isMorning ? ZenithColors.amber : ZenithColors.primaryLight,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoachScreen(initialPrompt: _journalPrompt),
            ),
          );
        },
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _ActionCard(data: actions[i]),
      ),
    );
  }
}

class _ActionCardData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCardData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionCardData data;

  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.color.withValues(alpha: 0.15),
              data.color.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: data.color.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, size: 24, color: data.color),
            ),
            const Spacer(),
            Text(
              data.label,
              style: ZenithTheme.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ZenithColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: ZenithTheme.dmSans(
                fontSize: 12,
                color: ZenithColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Habit Action Bottom Sheet ──
// ══════════════════════════════════════════════

class _HabitActionSheet extends StatefulWidget {
  final Habit habit;
  final VoidCallback onStartTimer;
  final ValueChanged<int> onComplete;

  const _HabitActionSheet({
    required this.habit,
    required this.onStartTimer,
    required this.onComplete,
  });

  @override
  State<_HabitActionSheet> createState() => _HabitActionSheetState();
}

class _HabitActionSheetState extends State<_HabitActionSheet> {
  late final FixedExtentScrollController _minuteController;
  int _selectedMinutes = 30;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.habit.targetValue ?? 30;
    // Each item = 5 min, index = minutes / 5 - 1 (starts at 5)
    _minuteController = FixedExtentScrollController(
      initialItem: (_selectedMinutes ~/ 5 - 1).clamp(0, 23),
    );
  }

  @override
  void dispose() {
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final skill = app.subSkills.where((s) => s.id == widget.habit.subSkillId).firstOrNull;
    final statColor = Domain.byId(skill?.domain ?? 'discipline')?.color ?? ZenithColors.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ZenithColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Habit info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    skill?.icon ?? '⭐',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.habit.name,
                          style: ZenithTheme.dmSans(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      Text(
                        '+${widget.habit.baseXP} XP \u00b7 ${skill?.name ?? ''}',
                        style: ZenithTheme.dmSans(
                            fontSize: 13, color: ZenithColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Start Timer button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStartTimer,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Start Timer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider with "or"
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: ZenithColors.textMuted.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or',
                      style: ZenithTheme.dmSans(
                          fontSize: 13, color: ZenithColors.textMuted)),
                ),
                Expanded(
                    child: Divider(
                        color: ZenithColors.textMuted.withValues(alpha: 0.2))),
              ],
            ),

            const SizedBox(height: 16),

            // Mark complete with time
            Text(
              'Mark complete with time spent',
              style: ZenithTheme.dmSans(
                  fontSize: 14, color: ZenithColors.textLight),
            ),
            const SizedBox(height: 8),

            // Minute wheel picker
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.25, 0.75, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selection highlight band
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: ZenithColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ZenithColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  // The wheel
                  SizedBox(
                    height: 120,
                    child: ListWheelScrollView.useDelegate(
                      controller: _minuteController,
                      itemExtent: 40,
                      diameterRatio: 1.5,
                      overAndUnderCenterOpacity: 0.4,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        _selectedMinutes = (index + 1) * 5;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 24, // 5 to 120 min in 5-min steps
                        builder: (context, index) {
                          final mins = (index + 1) * 5;
                          return Center(
                            child: Text(
                              '$mins min',
                              style: ZenithTheme.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: ZenithColors.text,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => widget.onComplete(_selectedMinutes),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Complete \u00b7 $_selectedMinutes min'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Wrap Button ──
// ══════════════════════════════════════════════

// ══════════════════════════════════════════════
// ── Completed Habit Sheet (with time editing) ──
// ══════════════════════════════════════════════

class _CompletedHabitSheet extends StatefulWidget {
  final Habit habit;
  final Completion? completion;
  final int? minutesSpent;
  final VoidCallback onUndo;
  final void Function(DateTime start, DateTime end) onTimeUpdated;

  const _CompletedHabitSheet({
    required this.habit,
    this.completion,
    this.minutesSpent,
    required this.onUndo,
    required this.onTimeUpdated,
  });

  @override
  State<_CompletedHabitSheet> createState() => _CompletedHabitSheetState();
}

class _CompletedHabitSheetState extends State<_CompletedHabitSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final c = widget.completion;
    if (c?.startTime != null && c?.endTime != null) {
      _startTime = TimeOfDay.fromDateTime(c!.startTime!);
      _endTime = TimeOfDay.fromDateTime(c.endTime!);
    } else {
      final now = TimeOfDay.now();
      final mins = widget.minutesSpent ?? 30;
      final startTotal = (now.hour * 60 + now.minute - mins).clamp(0, 1439);
      _startTime = TimeOfDay(hour: startTotal ~/ 60, minute: startTotal % 60);
      _endTime = now;
    }
  }

  DateTime _todayAt(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  int get _durationMinutes {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    return (e - s).clamp(1, 1440);
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final skill = app.subSkills.where((s) => s.id == widget.habit.subSkillId).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ZenithColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Habit info
            Row(
              children: [
                Text(
                  skill?.icon ?? '⭐',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.habit.name,
                          style: ZenithTheme.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        'Completed \u00b7 $_durationMinutes min',
                        style: ZenithTheme.dmSans(
                            fontSize: 13, color: ZenithColors.textLight),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded,
                    color: ZenithColors.primary, size: 28),
              ],
            ),

            const SizedBox(height: 24),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start',
                    time: _startTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: ZenithColors.textMuted),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'End',
                    time: _endTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onUndo,
                    child: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onTimeUpdated(
                        _todayAt(_startTime),
                        _todayAt(_endTime),
                      );
                    },
                    child: const Text('Save time'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ZenithColors.bgDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ZenithTheme.dmSans(
                fontSize: 11,
                color: ZenithColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: ZenithTheme.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ZenithColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Day Breakdown (clock-face radial) ──
// ══════════════════════════════════════════════

class _DaySegment {
  final String label;
  final int minutes;
  final double startHour; // 0.0–24.0 fractional hour
  final double endHour;
  final Color color;
  final String stat;

  const _DaySegment({
    required this.label,
    required this.minutes,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.stat,
  });
}

double _toFractionalHour(DateTime dt) =>
    dt.hour + dt.minute / 60.0 + dt.second / 3600.0;

// ── Swipeable Graphics (Clock Wheel + Skills Radar) ──

class _SwipeableGraphics extends StatefulWidget {
  final List<Habit> habits;
  final List<Completion> completions;
  final List<AdhocTask> adhocTasks;
  final int totalMinutesInvested;
  final List<SubSkill> subSkills;
  final StatSnapshot stats;
  final Archetype archetype;

  const _SwipeableGraphics({
    required this.habits,
    required this.completions,
    required this.adhocTasks,
    required this.totalMinutesInvested,
    required this.subSkills,
    required this.stats,
    required this.archetype,
  });

  @override
  State<_SwipeableGraphics> createState() => _SwipeableGraphicsState();
}

class _SwipeableGraphicsState extends State<_SwipeableGraphics> {
  int _currentPage = 0;
  static const _pageCount = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView(
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Page 1: Clock wheel
              _DayBreakdown(
                habits: widget.habits,
                completions: widget.completions,
                adhocTasks: widget.adhocTasks,
                totalMinutesInvested: widget.totalMinutesInvested,
              ),
              // Page 2: Skills radar
              _SkillsRadar(
                subSkills: widget.subSkills,
                stats: widget.stats,
                archetype: widget.archetype,
              ),
              // Page 3: Archetype card
              _ArchetypeCard(archetype: widget.archetype),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pageCount, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? ZenithColors.primary
                    : ZenithColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Skills Radar Chart ──

class _SkillsRadar extends StatelessWidget {
  final List<SubSkill> subSkills;
  final StatSnapshot stats;
  final Archetype archetype;

  const _SkillsRadar({
    required this.subSkills,
    required this.stats,
    required this.archetype,
  });

  @override
  Widget build(BuildContext context) {
    final domainTotals = stats.domainTotals(subSkills);
    final maxVal = domainTotals.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZenithColors.cardBorder),
      ),
      child: Column(
        children: [
          // Radar chart
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: Domain.all.map((d) {
                      final val = domainTotals[d.id] ?? 0;
                      return RadarEntry(
                        value: maxVal > 0 ? val / maxVal * 100 : 0,
                      );
                    }).toList(),
                    fillColor: archetype.color.withValues(alpha: 0.2),
                    borderColor: archetype.color.withValues(alpha: 0.8),
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBorderData:
                    const BorderSide(color: Colors.transparent),
                tickBorderData:
                    BorderSide(color: ZenithColors.cardBorder, width: 0.5),
                gridBorderData: BorderSide(
                    color: ZenithColors.textMuted.withValues(alpha: 0.15)),
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0),
                titlePositionPercentageOffset: 0.2,
                getTitle: (index, _) {
                  if (index >= Domain.all.length) {
                    return RadarChartTitle(text: '');
                  }
                  final d = Domain.all[index];
                  return RadarChartTitle(
                    text: '${d.icon} ${d.label}',
                    positionPercentageOffset: 0.05,
                  );
                },
                titleTextStyle: ZenithTheme.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ZenithColors.text,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sub-skill chips
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: subSkills.where((s) => s.xp > 0).map((skill) {
                  final domain = Domain.byId(skill.domain);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (domain?.color ?? ZenithColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (domain?.color ?? ZenithColors.primary)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(skill.icon,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          skill.name,
                          style: ZenithTheme.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ZenithColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${skill.level}',
                          style: ZenithTheme.mono(
                            fontSize: 10,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }
}

// ── Archetype Card ──

class _ArchetypeCard extends StatelessWidget {
  final Archetype archetype;
  const _ArchetypeCard({required this.archetype});

  static const _archetypeDomains = {
    'olympian': 'Physical',
    'maverick': 'Creative',
    'sage': 'Spiritual',
    'monk': 'Discipline',
    'architect': 'Intellectual',
    'oracle': 'Intellectual + Spiritual',
    'catalyst': 'Social',
    'muse': 'Social + Creative',
    'strategist': 'Intellectual + Discipline',
    'polymath': 'Multi-domain',
  };

  void _showArchetypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: ZenithColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Drag indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZenithColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Archetype image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      archetype.imagePath,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 280,
                        color: archetype.color.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(archetype.icon,
                              style: const TextStyle(fontSize: 80)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(archetype.icon,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          archetype.title,
                          style: ZenithTheme.cormorant(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    archetype.description,
                    style: ZenithTheme.dmSans(
                      fontSize: 15,
                      color: ZenithColors.textLight,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Domain & Activities
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ZenithTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOMAIN',
                          style: ZenithTheme.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ZenithColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: archetype.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _archetypeDomains[archetype.id] ?? '',
                            style: ZenithTheme.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: archetype.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CHARACTERISTICS',
                          style: ZenithTheme.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ZenithColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          archetype.activities,
                          style: ZenithTheme.dmSans(
                            fontSize: 14,
                            color: ZenithColors.text,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showArchetypeSheet(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: archetype.color.withValues(alpha: 0.06),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Archetype image — fill the entire card
              Image.asset(
                archetype.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    archetype.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
              // Bottom gradient overlay with text
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archetype.title,
                        style: ZenithTheme.cormorant(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        archetype.description,
                        style: ZenithTheme.dmSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }
}

class _DayBreakdown extends StatelessWidget {
  final List<Habit> habits;
  final List<Completion> completions;
  final List<AdhocTask> adhocTasks;
  final int totalMinutesInvested;

  const _DayBreakdown({
    required this.habits,
    required this.completions,
    required this.adhocTasks,
    required this.totalMinutesInvested,
  });

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final segments = <_DaySegment>[];

    // Helper to look up domain color from a subSkillId
    SubSkill? findSkill(String? subSkillId) =>
        subSkillId == null ? null : app.subSkills.where((s) => s.id == subSkillId).firstOrNull;

    // Habit completions with start/end times
    for (final c in completions) {
      if (!c.completed || c.startTime == null || c.endTime == null) continue;
      final habit = habits.where((h) => h.id == c.habitId).firstOrNull;
      if (habit == null) continue;
      final skill = findSkill(habit.subSkillId);
      final domainId = skill?.domain ?? 'discipline';
      segments.add(_DaySegment(
        label: habit.name,
        minutes: c.value ?? c.endTime!.difference(c.startTime!).inMinutes,
        startHour: _toFractionalHour(c.startTime!),
        endHour: _toFractionalHour(c.endTime!),
        color: Domain.byId(domainId)?.color ?? ZenithColors.primary,
        stat: domainId,
      ));
    }

    // Ad-hoc tasks with start/end
    for (final t in adhocTasks) {
      if (!t.completed || t.startTime == null || t.endTime == null) continue;
      final skill = findSkill(t.subSkillId);
      final domainId = skill?.domain ?? '';
      segments.add(_DaySegment(
        label: t.title,
        minutes:
            t.minutesSpent ?? t.endTime!.difference(t.startTime!).inMinutes,
        startHour: _toFractionalHour(t.startTime!),
        endHour: _toFractionalHour(t.endTime!),
        color: Domain.byId(domainId)?.color ?? ZenithColors.warmGray,
        stat: domainId,
      ));
    }

    // Sort by start time
    segments.sort((a, b) => a.startHour.compareTo(b.startHour));

    // Group time by stat for center display
    final statMinutes = <String, int>{};
    for (final s in segments) {
      if (s.stat.isEmpty) continue;
      statMinutes[s.stat] = (statMinutes[s.stat] ?? 0) + s.minutes;
    }

    final investedH = totalMinutesInvested ~/ 60;
    final investedM = totalMinutesInvested % 60;
    final dayName = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ][DateTime.now().weekday - 1];

    // Find the max stat minutes for bar scaling
    final maxStatMin =
        statMinutes.values.isEmpty ? 1 : statMinutes.values.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZenithColors.cardBorder),
      ),
      child: Column(
        children: [
          // ── Clock ──
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280, 280),
                  painter: _ClockWheelPainter(segments: segments),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName,
                      style: ZenithTheme.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ZenithColors.text,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      investedH > 0
                          ? '${investedH}h${investedM > 0 ? '${investedM}m' : ''} scheduled'
                          : '${investedM}m scheduled',
                      style: ZenithTheme.dmSans(
                        fontSize: 11,
                        color: ZenithColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stat bar chart ──
          if (statMinutes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...statMinutes.entries.map((e) {
              final label = StatSnapshot.domainLabels[e.key] ?? e.key;
              final color =
                  StatSnapshot.domainColors[e.key] ?? ZenithColors.primary;
              final icon = StatSnapshot.domainIcons[e.key] ?? '';
              final h = e.value ~/ 60;
              final m = e.value % 60;
              final fraction = e.value / maxStatMin;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Icon + label
                    SizedBox(
                      width: 72,
                      child: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              style: ZenithTheme.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ZenithColors.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bar
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              // Track
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Fill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                height: 6,
                                width: constraints.maxWidth * fraction,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time
                    SizedBox(
                      width: 40,
                      child: Text(
                        h > 0 ? '${h}h${m}m' : '${m}m',
                        style: ZenithTheme.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ZenithColors.text,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }
}

// ── Clock Wheel Painter ──

class _ClockWheelPainter extends CustomPainter {
  final List<_DaySegment> segments;

  _ClockWheelPainter({required this.segments});

  /// Convert fractional hour (0–24) to angle. 00:00 = top (−π/2).
  double _hourToAngle(double hour) =>
      -math.pi / 2 + (hour / 24.0) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.48;
    final innerR = size.width * 0.33;
    final tickOuterR = size.width * 0.495;
    final labelR = size.width * 0.43;

    // ── 1. Tick marks (every 15 min = 96 ticks) ──
    final tickPaint = Paint()
      ..color = ZenithColors.textMuted.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;
    final majorTickPaint = Paint()
      ..color = ZenithColors.textMuted.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 96; i++) {
      final angle = -math.pi / 2 + (i / 96) * 2 * math.pi;
      final isMajor = i % 4 == 0;
      final inner = isMajor ? outerR - 8 : outerR - 4;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle),
            center.dy + inner * math.sin(angle)),
        Offset(center.dx + tickOuterR * math.cos(angle),
            center.dy + tickOuterR * math.sin(angle)),
        isMajor ? majorTickPaint : tickPaint,
      );
    }

    // ── 2. Hour labels ──
    const labels = ['00', '03', '06', '09', '12', '15', '18', '21'];
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (i / 8) * 2 * math.pi;
      final lx = center.dx + labelR * math.cos(angle);
      final ly = center.dy + labelR * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: ZenithColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // ── 3. Track ring ──
    canvas.drawCircle(
      center,
      (outerR + innerR) / 2,
      Paint()
        ..color = ZenithColors.primaryPale.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerR - innerR,
    );

    // ── 4. Time-positioned arcs ──
    if (segments.isEmpty) return;

    final arcRect =
        Rect.fromCircle(center: center, radius: (outerR + innerR) / 2);
    final arcWidth = outerR - innerR;

    for (final seg in segments) {
      final startAngle = _hourToAngle(seg.startHour);
      var endAngle = _hourToAngle(seg.endHour);
      // Handle wrap-around midnight (unlikely for single day but safe)
      if (endAngle <= startAngle) endAngle += 2 * math.pi;
      final sweep = endAngle - startAngle;
      if (sweep <= 0) continue;

      // Glow
      canvas.drawArc(
        arcRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = seg.color.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth + 6
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Main arc
      canvas.drawArc(
        arcRect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt,
      );

      // Inner highlight
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: (outerR + innerR) / 2 - arcWidth * 0.2),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth * 0.25
          ..strokeCap = StrokeCap.butt,
      );

      // Label on arc
      if (sweep > 0.12) {
        final midAngle = startAngle + sweep / 2;
        final lr = (outerR + innerR) / 2;
        final lx = center.dx + lr * math.cos(midAngle);
        final ly = center.dy + lr * math.sin(midAngle);

        final maxChars = (sweep * 14).clamp(3, 16).toInt();
        var label = seg.label;
        if (label.length > maxChars) {
          label = '${label.substring(0, maxChars - 1)}…';
        }

        canvas.save();
        canvas.translate(lx, ly);
        // Rotate to follow arc tangent
        var rot = midAngle + math.pi / 2;
        // Flip if upside-down
        if (midAngle > math.pi * 0.25 && midAngle < math.pi * 1.25) {
          rot += math.pi;
        }
        canvas.rotate(rot);

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    // ── 5. Current time indicator (red tick) ──
    final now = DateTime.now();
    final nowAngle = _hourToAngle(now.hour + now.minute / 60.0);
    final indicatorPaint = Paint()
      ..color = ZenithColors.danger
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx + (innerR - 4) * math.cos(nowAngle),
          center.dy + (innerR - 4) * math.sin(nowAngle)),
      Offset(center.dx + (outerR + 4) * math.cos(nowAngle),
          center.dy + (outerR + 4) * math.sin(nowAngle)),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockWheelPainter old) => true;
}

// ══════════════════════════════════════════════
// ── Add Action FAB ──
// ══════════════════════════════════════════════

class _AddActionFAB extends StatelessWidget {
  final AppProvider app;
  const _AddActionFAB({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: ZenithColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ZenithColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: ZenithColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZenithColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _AddOption(
                icon: Icons.repeat_rounded,
                label: 'Add Daily Habit',
                subtitle: 'A custom habit you want to track every day',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddHabitDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _AddOption(
                icon: Icons.task_alt_rounded,
                label: 'Add One-off Task',
                subtitle: 'Something you did or want to do today',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddTaskDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _AddOption(
                icon: Icons.mic_rounded,
                label: 'Voice Log',
                subtitle: 'Record what you did — AI extracts the tasks',
                onTap: () {
                  Navigator.pop(ctx);
                  _startVoiceRecording(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'checkbox';
    final targetController = TextEditingController();
    String unit = 'minutes';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: ZenithColors.bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ZenithColors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'New Daily Habit',
                  style: ZenithTheme.cormorant(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: ZenithTheme.dmSans(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. Practice piano, Run 5K, Cold shower',
                    hintStyle: ZenithTheme.dmSans(
                      fontSize: 14,
                      color: ZenithColors.textMuted,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                // Habit type selector
                Wrap(
                  spacing: 8,
                  children: [
                    _TypeChip(
                      label: 'Do it',
                      selected: selectedType == 'checkbox',
                      onTap: () =>
                          setSheetState(() => selectedType = 'checkbox'),
                    ),
                    _TypeChip(
                      label: 'Timed',
                      selected: selectedType == 'timed',
                      onTap: () =>
                          setSheetState(() => selectedType = 'timed'),
                    ),
                    _TypeChip(
                      label: 'Count',
                      selected: selectedType == 'counter',
                      onTap: () =>
                          setSheetState(() => selectedType = 'counter'),
                    ),
                    _TypeChip(
                      label: 'Avoid',
                      selected: selectedType == 'abstinence',
                      onTap: () =>
                          setSheetState(() => selectedType = 'abstinence'),
                    ),
                  ],
                ),
                if (selectedType == 'timed' ||
                    selectedType == 'counter') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: targetController,
                          keyboardType: TextInputType.number,
                          style: ZenithTheme.dmSans(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: selectedType == 'timed'
                                ? 'Min'
                                : 'Count',
                            hintStyle: ZenithTheme.dmSans(
                              fontSize: 14,
                              color: ZenithColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedType == 'counter')
                        SizedBox(
                          width: 100,
                          child: TextField(
                            style: ZenithTheme.dmSans(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Unit (reps)',
                              hintStyle: ZenithTheme.dmSans(
                                fontSize: 14,
                                color: ZenithColors.textMuted,
                              ),
                            ),
                            onChanged: (v) => unit = v,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx);
                      app.addCustomHabit(
                        name: name,
                        type: selectedType,
                        targetValue:
                            int.tryParse(targetController.text.trim()),
                        unit: selectedType == 'timed'
                            ? 'minutes'
                            : unit.isNotEmpty
                                ? unit
                                : null,
                      );
                    },
                    child: const Text('Add Habit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: ZenithColors.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZenithColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Task',
                style: ZenithTheme.cormorant(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: ZenithTheme.dmSans(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'What did you do?',
                  hintStyle: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: ZenithColors.textMuted,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    app.addAdhocTask(v.trim());
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    app.addAdhocTask(text);
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startVoiceRecording(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceRecordingSheet(app: app),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZenithColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: ZenithColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ZenithTheme.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? ZenithColors.primary
              : ZenithColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: ZenithTheme.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : ZenithColors.text,
          ),
        ),
      ),
    );
  }
}

// ── Voice Recording Sheet ──

class _VoiceRecordingSheet extends StatefulWidget {
  final AppProvider app;
  const _VoiceRecordingSheet({required this.app});

  @override
  State<_VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends State<_VoiceRecordingSheet> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndProcess();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    setState(() => _isRecording = true);
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopAndProcess() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    HapticFeedback.mediumImpact();

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        if (mounted) Navigator.pop(context);
        await widget.app.processVoiceNote(file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: ZenithColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ZenithColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording ? 'Recording...' : 'Tap to start recording',
              style: ZenithTheme.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isRecording ? ZenithColors.danger : ZenithColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell me what you did today',
              style: ZenithTheme.dmSans(
                fontSize: 13,
                color: ZenithColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 72 : 64,
                height: _isRecording ? 72 : 64,
                decoration: BoxDecoration(
                  color:
                      _isRecording ? ZenithColors.danger : ZenithColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: _isRecording ? 32 : 28,
                ),
              ),
            ),
            if (widget.app.isProcessingVoiceNote) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Habit Card ──
// ══════════════════════════════════════════════

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final int? minutesSpent;
  final String? mediaPath;
  final String? mediaType;
  final VoidCallback onTap;
  final VoidCallback onMedia;

  const _HabitCard({
    required this.habit,
    required this.isCompleted,
    this.minutesSpent,
    this.mediaPath,
    this.mediaType,
    required this.onTap,
    required this.onMedia,
  });

  bool get _hasMedia {
    if (mediaPath == null) return false;
    return File(mediaPath!).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final skill = app.subSkills.where((s) => s.id == habit.subSkillId).firstOrNull;
    final statColor = Domain.byId(skill?.domain ?? 'discipline')?.color ?? ZenithColors.primary;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isCompleted ? statColor.withValues(alpha: 0.04) : null,
      child: Row(
        children: [
          // Leading icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              skill?.icon ?? '⭐',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: ZenithTheme.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? ZenithColors.textLight
                        : ZenithColors.text,
                  ).copyWith(
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: ZenithColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompleted && minutesSpent != null
                      ? '$minutesSpent min \u00b7 +${habit.baseXP} XP'
                      : '${habit.typeLabel} \u00b7 +${habit.baseXP} XP',
                  style: ZenithTheme.dmSans(
                    fontSize: 12,
                    color: ZenithColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Trailing
          if (isCompleted) ...[
            if (_hasMedia || true) // always show camera option when completed
              GestureDetector(
                onTap: onMedia,
                child: Icon(
                  _hasMedia
                      ? (mediaType == 'video'
                          ? Icons.videocam_rounded
                          : Icons.photo_rounded)
                      : Icons.camera_alt_outlined,
                  size: 18,
                  color: statColor.withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(width: 10),
            Icon(Icons.check_circle_rounded, size: 22, color: statColor),
          ] else
            Icon(Icons.chevron_right_rounded,
                size: 22, color: ZenithColors.textMuted),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Voice Task Time Entry Sheet ──
// ══════════════════════════════════════════════

class _VoiceTaskTimeSheet extends StatefulWidget {
  final List<AdhocTask> tasks;
  final AppProvider app;

  const _VoiceTaskTimeSheet({required this.tasks, required this.app});

  @override
  State<_VoiceTaskTimeSheet> createState() => _VoiceTaskTimeSheetState();
}

class _VoiceTaskTimeSheetState extends State<_VoiceTaskTimeSheet> {
  late final Map<String, int> _minutes; // taskId → minutes

  @override
  void initState() {
    super.initState();
    _minutes = {for (final t in widget.tasks) t.id: 30};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ZenithColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How long did these take?',
              style: ZenithTheme.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Add time spent for each task',
              style: ZenithTheme.dmSans(
                  fontSize: 13, color: ZenithColors.textLight),
            ),
            const SizedBox(height: 20),
            ...widget.tasks.map((task) {
              final mins = _minutes[task.id] ?? 30;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: ZenithTheme.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Decrement
                    GestureDetector(
                      onTap: () {
                        if (mins > 5) {
                          setState(() => _minutes[task.id] = mins - 5);
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: ZenithColors.bgDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Center(
                        child: Text(
                          '${mins}m',
                          style: ZenithTheme.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Increment
                    GestureDetector(
                      onTap: () {
                        setState(() => _minutes[task.id] = mins + 5);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: ZenithColors.bgDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      for (final task in widget.tasks) {
                        final mins = _minutes[task.id] ?? 30;
                        widget.app
                            .completeAdhocTaskWithDuration(task, mins);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── Ad-hoc Task Card ──
// ══════════════════════════════════════════════

class _AdhocTaskCard extends StatelessWidget {
  final AdhocTask task;
  final VoidCallback onToggle;

  const _AdhocTaskCard({
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final skill = task.subSkillId != null
        ? app.subSkills.where((s) => s.id == task.subSkillId).firstOrNull
        : null;
    final domainColor = Domain.byId(skill?.domain ?? 'discipline')?.color ?? ZenithColors.sage;

    return GlassCard(
      onTap: onToggle,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: task.completed
          ? domainColor.withValues(alpha: 0.04)
          : null,
      child: Row(
        children: [
          // Leading icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: domainColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: skill != null
                ? Text(skill.icon, style: const TextStyle(fontSize: 20))
                : Icon(Icons.mic_rounded,
                    size: 20, color: domainColor),
          ),
          const SizedBox(width: 14),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: ZenithTheme.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: task.completed
                        ? ZenithColors.textLight
                        : ZenithColors.text,
                  ).copyWith(
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: ZenithColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Voice logged${task.minutesSpent != null ? ' \u00b7 ${task.minutesSpent} min' : ''}${task.subSkillId != null ? ' \u00b7 +${task.xp} XP' : ''}',
                  style: ZenithTheme.dmSans(
                    fontSize: 12,
                    color: ZenithColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Trailing
          task.completed
              ? Icon(Icons.check_circle_rounded, size: 22, color: domainColor)
              : Icon(Icons.radio_button_unchecked_rounded,
                  size: 22, color: ZenithColors.textMuted),
        ],
      ),
    );
  }
}
