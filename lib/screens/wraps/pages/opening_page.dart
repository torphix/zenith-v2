import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';
import '../painters/particle_painter.dart';

class OpeningPage extends StatefulWidget {
  final int dayNumber;
  final DateTime date;
  final VoidCallback? onAnimationComplete;

  const OpeningPage({
    super.key,
    required this.dayNumber,
    required this.date,
    this.onAnimationComplete,
  });

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Particle field
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: ParticlePainter(
                  animationValue: _particleController.value,
                  color: Colors.white,
                  particleCount: 20,
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "DAY" label
                Text(
                  'DAY',
                  style: ZenithTheme.dmSans(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),

                // Day number with fadeIn + scale
                Text(
                  '${widget.dayNumber}',
                  style: ZenithTheme.cormorant(
                    fontSize: 72,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                    ),

                const SizedBox(height: 8),

                // Date
                Text(
                  DateFormat('MMMM d, y').format(widget.date),
                  style: ZenithTheme.dmSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
