import 'package:flutter/foundation.dart';

/// Centralized logger for Zenith. Logs to console in debug mode.
class Log {
  Log._();

  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) debugPrint('[$tag] $error');
      if (stackTrace != null) debugPrint('[$tag] $stackTrace');
    }
  }

  static void warn(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] WARN: $message');
    }
  }

  /// Returns a user-friendly error message from an exception.
  static String friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('permission-denied') || msg.contains('permission_denied')) {
      return 'Permission denied. Please try signing in again.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (msg.contains('not-found')) {
      return 'Data not found. It may have been deleted.';
    }
    if (msg.contains('unauthenticated') || msg.contains('requires auth')) {
      return 'Session expired. Please restart the app.';
    }
    if (msg.contains('deadline-exceeded') || msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
