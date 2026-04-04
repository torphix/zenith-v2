import 'package:flutter/material.dart';

import '../theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: ZenithColors.cardBorder),
        ),
        child: child,
      ),
    );
  }
}
