// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : auth_debug_log.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

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
