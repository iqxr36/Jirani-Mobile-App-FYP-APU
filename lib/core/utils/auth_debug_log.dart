import 'package:flutter/foundation.dart';

/// Debug-only auth flow logging. No-ops in release/profile builds.
void authDebugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Debug-only auth error logging without credentials or identifiers.
void authDebugLogError(String context, Object error, [StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  debugPrint('$context: $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}
