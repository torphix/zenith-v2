import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/archetype.dart';
import '../../../theme.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _currentStep = 0;
  int _factIndex = 0;
  int _archetypePage = 0;
  late final PageController _archetypeController;
  Timer? _autoScrollTimer;

  static const _steps = [
    ('Analyzing your goals', Icons.track_changes_rounded),
    ('Designing your daily habits', Icons.wb_sunny_rounded),
    ('Building your quests', Icons.explore_rounded),
    ('Calibrating difficulty', Icons.tune_rounded),
    ('Crafting your 30-day path', Icons.auto_awesome_rounded),
  ];

  static const _facts = [
    'It takes an average of 66 days to form a habit — but real momentum starts in the first 7.',
    'People who write down their goals are 42% more likely to achieve them.',
    'The most successful habit builders start with just one keystone habit.',
    'Your programme is tailored to everything you told us — no two are alike.',
    'Consistency beats intensity. 15 minutes daily outperforms 2 hours once a week.',
  ];

  @override
  void initState() {
    super.initState();
    _archetypeController = PageController(viewportFraction: 0.85);
    _advanceSteps();
    _cycleFacts();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _archetypeController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _advanceSteps() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
        _advanceSteps();
      }
    });
  }

  void _cycleFacts() {
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      setState(() => _factIndex = (_factIndex + 1) % _facts.length);
      _cycleFacts();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted || !_archetypeController.hasClients) return;
      final next = (_archetypePage + 1) % Archetype.all.length;
      _archetypeController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  minHeight: 3,
                  backgroundColor:
                      ZenithColors.primaryPale.withValues(alpha: 0.2),
                  color: ZenithColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          const SizedBox(height: 20),

          // ── Title ──
          Text(
            'Building your programme',
            style: ZenithTheme.cormorant(
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 24),

          // ── Archetype carousel ──
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _archetypeController,
              itemCount: Archetype.all.length,
              onPageChanged: (i) => setState(() => _archetypePage = i),
              itemBuilder: (context, index) {
                final arch = Archetype.all[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Archetype image
                        Image.asset(
                          arch.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: arch.color.withValues(alpha: 0.2),
                            child: Center(
                              child: Text(arch.icon,
                                  style: const TextStyle(fontSize: 64)),
                            ),
                          ),
                        ),
                        // Bottom gradient + text
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding:
                                const EdgeInsets.fromLTRB(16, 48, 16, 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  arch.title,
                                  style: ZenithTheme.cormorant(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  arch.description,
                                  style: ZenithTheme.dmSans(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
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
                );
              },
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

          const SizedBox(height: 16),

          // ── Page dots ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(Archetype.all.length, (i) {
              final isActive = i == _archetypePage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? ZenithColors.primary
                      : ZenithColors.textMuted.withValues(alpha: 0.3),
                ),
              );
            }),
          ),

          const Spacer(),

          // ── Step indicators ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: List.generate(_steps.length, (i) {
                final isCompleted = i < _currentStep;
                final isCurrent = i == _currentStep;
                return _StepRow(
                  label: _steps[i].$1,
                  icon: _steps[i].$2,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  index: i,
                );
              }),
            ),
          ),

          const Spacer(),

          // ── Fact card ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Container(
                key: ValueKey(_factIndex),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ZenithColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: ZenithColors.amber,
                      size: 20,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _facts[_factIndex],
                      textAlign: TextAlign.center,
                      style: ZenithTheme.dmSans(
                        fontSize: 13,
                        color: ZenithColors.textLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Step Row ──

class _StepRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final int index;

  const _StepRow({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Status icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? ZenithColors.primary
                  : isCurrent
                      ? ZenithColors.primary.withValues(alpha: 0.12)
                      : ZenithColors.primaryPale.withValues(alpha: 0.15),
              border: Border.all(
                color: isCompleted || isCurrent
                    ? ZenithColors.primary.withValues(alpha: 0.4)
                    : ZenithColors.primaryPale.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : isCurrent
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: ZenithColors.primary,
                        ),
                      )
                    : Icon(icon,
                        size: 14,
                        color: ZenithColors.textMuted
                            .withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 14),
          // Label
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: ZenithTheme.dmSans(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted
                    ? ZenithColors.primary
                    : isCurrent
                        ? ZenithColors.text
                        : ZenithColors.textMuted,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (150 * index).ms, duration: 400.ms)
        .slideX(begin: 0.05, end: 0, delay: (150 * index).ms, duration: 400.ms);
  }
}
