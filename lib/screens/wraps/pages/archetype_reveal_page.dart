import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/archetype.dart';
import '../../../theme.dart';
import '../painters/glow_ring_painter.dart';

class ArchetypeRevealPage extends StatefulWidget {
  final Archetype archetype;
  final String? archetypeShift; // old archetype id if changed, null if same
  final VoidCallback? onAnimationComplete;

  const ArchetypeRevealPage({
    super.key,
    required this.archetype,
    this.archetypeShift,
    this.onAnimationComplete,
  });

  @override
  State<ArchetypeRevealPage> createState() => _ArchetypeRevealPageState();
}

class _ArchetypeRevealPageState extends State<ArchetypeRevealPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.archetype.color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.black, 0.6)!,
            color,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "ARCHETYPE SHIFT" badge
            if (widget.archetypeShift != null)
              Text(
                'ARCHETYPE SHIFT',
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                  color: ZenithColors.gold,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .then()
                  .custom(
                    duration: 400.ms,
                    builder: (_, value, child) => Transform.translate(
                      offset: Offset(0, -4 * (1 - value)),
                      child: child,
                    ),
                  ),

            if (widget.archetypeShift != null) const SizedBox(height: 12),

            // "ARCHETYPE" label
            Text(
              'ARCHETYPE',
              style: ZenithTheme.dmSans(
                fontSize: 12,
                letterSpacing: 4,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 24),

            // Glow ring + archetype image
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) => SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: GlowRingPainter(
                    progress: _glowController.value,
                    color: color,
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.archetype.imagePath,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          widget.archetype.icon,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Archetype title
            Text(
              widget.archetype.title,
              style: ZenithTheme.cormorant(
                fontSize: 36,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.archetype.description,
                textAlign: TextAlign.center,
                style: ZenithTheme.dmSans(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}
