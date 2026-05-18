import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme.dart';

class HighlightsPage extends StatefulWidget {
  final List<String> highlights;
  final String? coachNote;
  final VoidCallback? onAnimationComplete;

  const HighlightsPage({
    super.key,
    required this.highlights,
    this.coachNote,
    this.onAnimationComplete,
  });

  @override
  State<HighlightsPage> createState() => _HighlightsPageState();
}

class _HighlightsPageState extends State<HighlightsPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // highlights stagger: 200ms each, + coach note extra 400ms, + 500ms buffer
    var totalDelay = widget.highlights.length * 200;
    if (widget.coachNote != null && widget.coachNote!.isNotEmpty) {
      totalDelay += 400;
    }
    totalDelay += 500;
    _timer = Timer(Duration(milliseconds: totalDelay), () {
      if (mounted) widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightDelay = widget.highlights.length * 200;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A2E1A),
            ZenithColors.primaryDeep,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'HIGHLIGHTS',
                style: ZenithTheme.dmSans(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Highlight items
              for (var i = 0; i < widget.highlights.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: const BoxDecoration(
                          color: ZenithColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.highlights[i],
                          style: ZenithTheme.dmSans(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: (i * 200).ms,
                      )
                      .slideX(
                        begin: 0.15,
                        end: 0,
                        duration: 400.ms,
                        delay: (i * 200).ms,
                      ),
                ),

              // Coach note
              if (widget.coachNote != null && widget.coachNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.coachNote!,
                    style: ZenithTheme.dmSans(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(
                        duration: 400.ms,
                        delay: (highlightDelay + 400).ms,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
