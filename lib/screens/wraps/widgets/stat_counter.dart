import 'package:flutter/material.dart';

/// Animated number counter that counts up from 0 to [targetValue].
///
/// Uses [Curves.easeOut] for a natural deceleration feel. Supports
/// a [prefix] (e.g. "+") and [suffix] (e.g. "%" or " XP") around the number.
class StatCounter extends StatefulWidget {
  const StatCounter({
    super.key,
    required this.targetValue,
    this.duration = const Duration(seconds: 1),
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int targetValue;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  @override
  State<StatCounter> createState() => _StatCounterState();
}

class _StatCounterState extends State<StatCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _buildAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(StatCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue ||
        oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _buildAnimation();
      _controller
        ..reset()
        ..forward();
    }
  }

  void _buildAnimation() {
    _animation = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
