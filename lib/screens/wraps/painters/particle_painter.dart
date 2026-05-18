import 'dart:math';

import 'package:flutter/material.dart';

/// Floating particles background painter for wrap opening pages.
///
/// Generates [particleCount] small circles that drift upward with a slight
/// orbital wobble. Uses a seeded [Random] for deterministic particle positions
/// across rebuilds.
class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.animationValue,
    this.color = Colors.white,
    this.particleCount = 20,
  });

  /// Animation progress from 0.0 to 1.0, drives particle motion.
  final double animationValue;

  /// Base color for the particles.
  final Color color;

  /// Number of particles to render.
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // seeded for consistency

    for (int i = 0; i < particleCount; i++) {
      // Deterministic base position
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      // Per-particle variation
      final radius = 2.0 + rng.nextDouble() * 2.0; // 2-4px
      final opacity = 0.1 + rng.nextDouble() * 0.3; // 10-40%
      final speed = 0.5 + rng.nextDouble() * 0.5; // drift speed factor
      final phase = rng.nextDouble() * 2 * pi; // orbital phase offset

      // Upward drift + orbital wobble
      final drift = animationValue * speed * size.height * 0.3;
      final wobbleX = sin(animationValue * 2 * pi + phase) * 12;
      final wobbleY = cos(animationValue * 2 * pi * 0.7 + phase) * 8;

      final x = baseX + wobbleX;
      final y = (baseY - drift + wobbleY) % size.height;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
