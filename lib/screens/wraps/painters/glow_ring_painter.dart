import 'package:flutter/material.dart';

/// Expanding glow ring drawn behind an archetype icon.
///
/// Draws a blurred circle that expands from zero to full size based on
/// [progress], plus a thin solid ring at the outer edge.
class GlowRingPainter extends CustomPainter {
  GlowRingPainter({
    required this.progress,
    required this.color,
  });

  /// Expansion progress from 0.0 (invisible) to 1.0 (full size).
  final double progress;

  /// Base color for the glow and ring.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final radius = maxRadius * progress;

    // Glow — blurred filled circle
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius, glowPaint);

    // Thin solid ring at the edge
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(GlowRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
