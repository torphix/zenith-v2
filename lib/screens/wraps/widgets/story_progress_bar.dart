import 'package:flutter/material.dart';

/// Instagram-style segmented progress bar for Stories wraps.
///
/// Shows one thin horizontal bar per page. Completed pages are solid white,
/// the current page fills from left based on [currentProgress], and future
/// pages are white at 30% opacity.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.totalPages,
    required this.currentPage,
    this.currentProgress = 0.0,
  });

  final int totalPages;
  final int currentPage;

  /// 0.0 to 1.0 fill for the active segment.
  final double currentProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 8,
      ),
      child: Row(
        children: List.generate(totalPages, (index) {
          final isCompleted = index < currentPage;
          final isCurrent = index == currentPage;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
              child: _SegmentBar(
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                progress: isCurrent ? currentProgress : 0.0,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.isCompleted,
    required this.isCurrent,
    required this.progress,
  });

  final bool isCompleted;
  final bool isCurrent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: Stack(
          children: [
            // Background track
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            // Fill
            if (isCompleted)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              )
            else if (isCurrent)
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
