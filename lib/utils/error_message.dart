import 'dart:async';

/// Converts technical network/API exceptions into messages a normal HR user
/// can understand. Never expose raw SocketException/HTTP jargon in the UI.
class ErrorMessage {
  static String from(Object error,
      {String fallback = 'Something went wrong. Please try again.'}) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (error is TimeoutException ||
        lower.contains('timeout') ||
        lower.contains('timed out')) {
      return 'The server is taking too long to respond. Please check your internet connection and try again.';
    }
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection closed') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception') ||
        lower.contains('no internet')) {
      return 'No internet connection or the RecruitIQ server is unavailable. Check your connection and try again.';
    }
    if (lower.contains('401') ||
        lower.contains('session has expired') ||
        lower.contains('unauthorized')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('403') || lower.contains('permission')) {
      return 'You do not have permission to perform this action.';
    }
    if (lower.contains('404')) {
      return 'The requested RecruitIQ service or record was not found.';
    }
    if (lower.contains('429')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504')) {
      return 'RecruitIQ server is temporarily unavailable. Please try again shortly.';
    }
    if (raw.isEmpty) return fallback;
    return raw;
  }
}
