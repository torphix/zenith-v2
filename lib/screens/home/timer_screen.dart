import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/habit.dart';
import '../../models/sub_skill.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';

class TimerScreen extends StatefulWidget {
  final Habit habit;
  final AppProvider app;

  const TimerScreen({super.key, required this.habit, required this.app});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late final Stopwatch _stopwatch;
  Timer? _ticker;
  bool _running = false;
  int _elapsedSeconds = 0;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    _stopwatch.start();
    _running = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
    HapticFeedback.lightImpact();
  }

  void _pause() {
    _stopwatch.stop();
    _ticker?.cancel();
    setState(() => _running = false);
    HapticFeedback.lightImpact();
  }

  void _resume() {
    _start();
    setState(() {});
  }

  void _stop() {
    _stopwatch.stop();
    _ticker?.cancel();
    final minutes = (_elapsedSeconds / 60).ceil().clamp(1, 999);
    widget.app.completeHabitWithDuration(widget.habit, minutes);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final subSkill = widget.app.subSkills
        .where((s) => s.id == widget.habit.subSkillId)
        .firstOrNull;
    final domain = subSkill != null ? Domain.byId(subSkill.domain) : null;
    final statColor = domain?.color ?? ZenithColors.primary;
    final statIcon = subSkill?.icon ?? '';
    final statLabel = subSkill?.name ?? '';
    final targetSeconds = (widget.habit.targetValue ?? 0) * 60;
    final progress = targetSeconds > 0
        ? (_elapsedSeconds / targetSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A1B4E),
              Color.lerp(const Color(0xFF1A1030), statColor, 0.15)!,
              const Color(0xFF0E0A1A),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Cancel without saving
                        _stopwatch.stop();
                        _ticker?.cancel();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            statIcon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statLabel,
                            style: ZenithTheme.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Timer ring ──
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = _running ? _pulseController.value * 0.03 : 0.0;
                  return Transform.scale(
                    scale: 1.0 + pulse,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _TimerRingPainter(
                      progress: progress,
                      color: statColor,
                      isRunning: _running,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: ZenithTheme.cormorant(
                              fontSize: 56,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: 2,
                            ),
                          ),
                          if (targetSeconds > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'of ${widget.habit.targetValue} min',
                              style: ZenithTheme.dmSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 32),

              // ── Habit name ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  widget.habit.name,
                  textAlign: TextAlign.center,
                  style: ZenithTheme.cormorant(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Controls ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stop button
                  GestureDetector(
                    onTap: _stop,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(Icons.stop_rounded,
                          color: Colors.white.withValues(alpha: 0.7), size: 26),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Pause / Resume
                  GestureDetector(
                    onTap: _running ? _pause : _resume,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statColor,
                        boxShadow: [
                          BoxShadow(
                            color: statColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Placeholder for symmetry
                  const SizedBox(width: 56, height: 56),
                ],
              ),

              const SizedBox(height: 16),

              // Stop hint
              Text(
                _running ? 'Tap stop to save' : 'Paused',
                style: ZenithTheme.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer Ring Painter ──

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRunning;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, trackPaint);

    // Inner subtle ring
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 20, innerPaint);

    if (progress <= 0) return;

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

    // Glow arc
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.isRunning != isRunning;
}
