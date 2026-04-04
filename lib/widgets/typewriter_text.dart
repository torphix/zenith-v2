import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration charDuration;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.charDuration = const Duration(milliseconds: 40),
    this.style,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = '';
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayed = widget.text.substring(0, _index + 1);
          _index++;
        });
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style ??
          ZenithTheme.cormorant(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
    );
  }
}
