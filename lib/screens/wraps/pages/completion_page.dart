import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';


import '../../../theme.dart';
import '../painters/progress_ring_painter.dart';
import '../widgets/stat_counter.dart';

class CompletionPage extends StatefulWidget {
  final double completionRate; // 0.0 to 1.0
  final int habitsCompleted;
  final int habitsTotal;
  final VoidCallback? onAnimationComplete;

  const CompletionPage({
    super.key,
    required this.completionRate,
    required this.habitsCompleted,
    required this.habitsTotal,
    this.onAnimationComplete,
  });

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringAnimation;
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnimation = Tween<double>(begin: 0, end: widget.completionRate)
        .animate(CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOut,
    ));
    _ringController.forward();

    if (widget.completionRate == 1.0) {
      _confettiController = ConfettiController(
        duration: const Duration(seconds: 2),
      )..play();
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ZenithColors.primaryDeep, ZenithColors.primary],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress ring + percentage
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring
                      AnimatedBuilder(
                        animation: _ringAnimation,
                        builder: (context, _) => CustomPaint(
                          size: const Size(200, 200),
                          painter: ProgressRingPainter(
                            progress: _ringAnimation.value,
                            color: ZenithColors.primary,
                          ),
                        ),
                      ),

                      // Counter
                      StatCounter(
                        targetValue:
                            (widget.completionRate * 100).round(),
                        suffix: '%',
                        style: ZenithTheme.mono(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // "completed"
                Text(
                  'completed',
                  style: ZenithTheme.cormorant(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 8),

                // "{X} of {Y} habits"
                Text(
                  '${widget.habitsCompleted} of ${widget.habitsTotal} habits',
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          if (_confettiController != null)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
              ),
            ),
        ],
      ),
    );
  }
}
