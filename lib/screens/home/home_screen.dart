import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../models/adhoc_task.dart';
import '../../models/habit.dart';
import '../../models/stat_snapshot.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/snackbar_helper.dart';

import '../wraps/daily_wrap_screen.dart';

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
    final greeting = _greeting();
    final isEvening = DateTime.now().hour >= 18;

    return Scaffold(
      backgroundColor: ZenithColors.bg,
      floatingActionButton: _VoiceNoteFAB(app: app),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.refreshTodayData,
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                                  '$greeting, ${app.profile?.name ?? 'Seeker'}',
                                  style: ZenithTheme.cormorant(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  programme != null
                                      ? 'Day ${programme.currentDay} of ${programme.name}'
                                      : 'No active programme',
                                  style: ZenithTheme.dmSans(
                                    fontSize: 13,
                                    color: ZenithColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Archetype badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: app.archetype.color
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: app.archetype.color
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  app.archetype.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  app.archetype.name,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: app.archetype.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quick stats ──
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.local_fire_department_rounded,
                            label: '${app.stats.currentStreak}',
                            sub: 'streak',
                            color: ZenithColors.amber,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.bolt_rounded,
                            label: '${app.todayXP}',
                            sub: 'XP today',
                            color: ZenithColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            icon: Icons.star_rounded,
                            label: 'Lv ${app.stats.level}',
                            sub: '${(app.stats.levelProgress * 100).toInt()}%',
                            color: ZenithColors.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Today's progress ring ──
                      if (app.habits.isNotEmpty)
                        _ProgressRing(
                          completionRate: app.todayCompletionRate,
                          xp: app.todayXP,
                          stats: app.stats,
                        ),
                      if (app.habits.isNotEmpty) const SizedBox(height: 28),

                      // ── Section: Today's Habits ──
                      if (app.habits.isNotEmpty) ...[
                        Text(
                          'Today\'s Habits',
                          style: ZenithTheme.cormorant(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Habits list ──
              if (app.habits.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = app.habits[index];
                        final isCompleted = app.isHabitCompleted(habit.id);
                        final completion =
                            app.getCompletionForHabit(habit.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HabitCard(
                            habit: habit,
                            isCompleted: isCompleted,
                            photoUrl: completion?.photoUrl,
                            onToggle: () => app.toggleHabit(habit),
                            onPhoto: () => _pickPhoto(context, app, habit),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: (100 * index).ms,
                              duration: 300.ms,
                            )
                            .slideX(begin: 0.05, end: 0);
                      },
                      childCount: app.habits.length,
                    ),
                  ),
                ),

              // ── Section: Voice-logged Tasks ──
              if (app.todayAdhocTasks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      children: [
                        Icon(Icons.mic_rounded,
                            size: 18, color: ZenithColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Voice-logged Tasks',
                          style: ZenithTheme.cormorant(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (app.todayAdhocTasks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = app.todayAdhocTasks[index];
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
                      },
                      childCount: app.todayAdhocTasks.length,
                    ),
                  ),
                ),

              // ── Processing voice note indicator ──
              if (app.isProcessingVoiceNote)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
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

              // ── Evening: Daily Wrap CTA ──
              if (isEvening && app.todayCompletionRate > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      color: ZenithColors.primaryDeep.withValues(alpha: 0.08),
                      onTap: () async {
                        final wrap = await app.generateDailyWrap();
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyWrapScreen(wrap: wrap),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  ZenithColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_awesome_rounded,
                                size: 22, color: ZenithColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Daily Wrap is ready',
                                  style: ZenithTheme.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Review your day with your AI coach',
                                  style: ZenithTheme.dmSans(
                                    fontSize: 13,
                                    color: ZenithColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: ZenithColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Daily wrap button (non-evening fallback) ──
              if (!isEvening && app.todayCompletionRate > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final wrap = await app.generateDailyWrap();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyWrapScreen(wrap: wrap),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded,
                            size: 18),
                        label: const Text('View Daily Wrap'),
                      ),
                    ),
                  ),
                ),

              // ── Empty state when no habits and no tasks ──
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

  void _pickPhoto(
      BuildContext context, AppProvider app, Habit habit) async {
    final storageService = StorageService();
    final file = await storageService.pickPhoto();
    if (file != null) {
      await app.addCompletionPhoto(habit.id, File(file.path));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Voice Note FAB ──

class _VoiceNoteFAB extends StatefulWidget {
  final AppProvider app;
  const _VoiceNoteFAB({required this.app});

  @override
  State<_VoiceNoteFAB> createState() => _VoiceNoteFABState();
}

class _VoiceNoteFABState extends State<_VoiceNoteFAB> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

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
    _recordingPath = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _recordingPath!,
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
        await widget.app.processVoiceNote(file);
        if (!mounted) return;
        final error = widget.app.consumeError();
        if (error != null) {
          showErrorSnackbar(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isRecording ? 72 : 60,
        height: _isRecording ? 72 : 60,
        decoration: BoxDecoration(
          color: _isRecording
              ? ZenithColors.danger
              : ZenithColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording
                      ? ZenithColors.danger
                      : ZenithColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: _isRecording ? 32 : 28,
        ),
      ),
    );
  }
}

// ── Progress Ring ──

class _ProgressRing extends StatelessWidget {
  final double completionRate;
  final int xp;
  final StatSnapshot stats;

  const _ProgressRing({
    required this.completionRate,
    required this.xp,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 8,
                      backgroundColor:
                          ZenithColors.primaryPale.withValues(alpha: 0.3),
                      color: ZenithColors.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(completionRate * 100).toInt()}%',
                        style: ZenithTheme.mono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ZenithColors.primary,
                        ),
                      ),
                      Text(
                        'complete',
                        style: ZenithTheme.dmSans(
                          fontSize: 12,
                          color: ZenithColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeOut);
  }
}

// ── Stat Chip ──

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 14,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  style: ZenithTheme.dmSans(
                    fontSize: 10,
                    color: ZenithColors.textMuted,
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

// ── Habit Card ──

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final String? photoUrl;
  final VoidCallback onToggle;
  final VoidCallback onPhoto;

  const _HabitCard({
    required this.habit,
    required this.isCompleted,
    this.photoUrl,
    required this.onToggle,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(16),
      color: isCompleted
          ? ZenithColors.primary.withValues(alpha: 0.08)
          : null,
      child: Row(
        children: [
          // Checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? ZenithColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted
                    ? ZenithColors.primary
                    : ZenithColors.textMuted.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),

          // Info
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
                Row(
                  children: [
                    Text(
                      StatSnapshot.statIcons[habit.primaryStat] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.typeLabel} +${habit.baseXP} XP',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Photo button
          if (isCompleted)
            IconButton(
              onPressed: onPhoto,
              icon: Icon(
                photoUrl != null
                    ? Icons.photo_rounded
                    : Icons.camera_alt_outlined,
                size: 20,
                color: ZenithColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ad-hoc Task Card ──

class _AdhocTaskCard extends StatelessWidget {
  final AdhocTask task;
  final VoidCallback onToggle;

  const _AdhocTaskCard({
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(16),
      color: task.completed
          ? ZenithColors.mint.withValues(alpha: 0.12)
          : null,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: task.completed
                  ? ZenithColors.sage
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: task.completed
                    ? ZenithColors.sage
                    : ZenithColors.textMuted.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
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
                Row(
                  children: [
                    Icon(Icons.mic_rounded,
                        size: 12, color: ZenithColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Voice logged${task.primaryStat != null ? ' +${task.xp} XP' : ''}',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        color: ZenithColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
