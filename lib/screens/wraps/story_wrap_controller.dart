import 'dart:async';

import 'package:flutter/foundation.dart';

/// Controller for managing Stories-style page progression in wraps.
///
/// Handles forward/back navigation, auto-advance after animations complete,
/// and pause/resume for long-press interactions.
class StoryWrapController extends ChangeNotifier {
  StoryWrapController({
    required this.totalPages,
    this.autoAdvanceDelay = const Duration(seconds: 3),
  });

  final int totalPages;
  final Duration autoAdvanceDelay;

  int _currentPage = 0;
  bool _isPaused = false;
  Timer? _autoAdvanceTimer;

  int get currentPage => _currentPage;
  bool get isPaused => _isPaused;
  bool get isLastPage => _currentPage >= totalPages - 1;

  /// Advance to the next page. Cancels any pending auto-advance timer.
  void advance() {
    _cancelTimer();
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// Go back to the previous page. Cancels any pending auto-advance timer.
  void goBack() {
    _cancelTimer();
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Pause auto-advance (e.g. on long press).
  void pause() {
    _cancelTimer();
    _isPaused = true;
    notifyListeners();
  }

  /// Resume after a pause (e.g. on long press release).
  void resume() {
    _isPaused = false;
    notifyListeners();
  }

  /// Called by each page when its entrance animation completes.
  /// Starts a timer that will auto-advance after [autoAdvanceDelay].
  void startAutoAdvance() {
    _cancelTimer();
    if (_isPaused || isLastPage) return;

    _autoAdvanceTimer = Timer(autoAdvanceDelay, () {
      if (!_isPaused) advance();
    });
  }

  void _cancelTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
