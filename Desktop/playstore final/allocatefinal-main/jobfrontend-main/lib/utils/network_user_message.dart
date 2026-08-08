import 'dart:async';
import 'dart:io';

/// Maps low-level [SocketException], timeouts, and typical [http] client errors
/// into copy users understand. Never surfaces backend URLs or dart-define hints.
class NetworkUserMessage {
  NetworkUserMessage._();

  static const String connectivityTitle = 'Internet connection is not available';
  static const String connectivityBody =
      'Turn on Wi‑Fi or mobile data, then try again.';

  static const String timeoutTitle = 'Connection timed out';
  static const String timeoutBody =
      'Please check your internet connection and try again.';

  static const String serverUnreachableTitle =
      'Internet connection is not available';
  static const String serverUnreachableBody =
      'We could not reach JobAllocate right now. Check your connection and try again.';

  /// Non-null when [error] looks like a connectivity / reachability problem.
  static ({String title, String message})? describe(Object error) {
    if (error is SocketException) {
      return (title: connectivityTitle, message: connectivityBody);
    }
    if (error is TimeoutException) {
      return (title: timeoutTitle, message: timeoutBody);
    }

    final raw = error.toString();
    final s = raw.toLowerCase();

    if (_looksLikeOfflineOrUnreachable(s)) {
      return (title: connectivityTitle, message: connectivityBody);
    }

    if (s.contains('timeoutexception') || s.contains('timed out')) {
      return (title: timeoutTitle, message: timeoutBody);
    }

    if (s.contains('clientexception') &&
        (s.contains('connection') ||
            s.contains('socket') ||
            s.contains('timed out') ||
            s.contains('failed'))) {
      return (title: serverUnreachableTitle, message: serverUnreachableBody);
    }

    // Dev-style API URL / HTML page errors → never show raw URL to users
    if (s.contains('api_base_url') ||
        s.contains('laravel api') ||
        s.contains('configured api base') ||
        s.contains('returned a web page instead of json') ||
        s.contains('10.0.2.2') ||
        s.contains('/api/v1') ||
        (s.contains('http://') || s.contains('https://'))) {
      return (title: serverUnreachableTitle, message: serverUnreachableBody);
    }

    // Transient server/DB contention (SQLite lock) — never show SQLSTATE blobs.
    if (s.contains('database is locked') ||
        s.contains('sqlstate') ||
        s.contains('server is busy') ||
        s.contains('database.sqlite')) {
      return (
        title: 'Something went wrong',
        message: 'Please try again in a moment.',
      );
    }

    return null;
  }

  static bool _looksLikeOfflineOrUnreachable(String s) {
    return s.contains('socketexception') ||
        s.contains('connection timed out') ||
        s.contains('connection refused') ||
        s.contains('network is unreachable') ||
        s.contains('host lookup failed') ||
        s.contains('failed host lookup') ||
        s.contains('name or service not known') ||
        s.contains('network is unreachable') ||
        s.contains('no address associated') ||
        s.contains('software caused connection abort') ||
        s.contains('connection reset');
  }

  /// Short paragraph for snackbars / single-line contexts.
  static String shortSummary(Object error) {
    final d = describe(error);
    if (d != null) return d.message;
    const prefix = 'Exception: ';
    final t = error.toString();
    if (t.startsWith(prefix)) return t.substring(prefix.length);
    // Never dump long technical blobs
    if (t.length > 160 ||
        t.toLowerCase().contains('http://') ||
        t.toLowerCase().contains('https://')) {
      return serverUnreachableBody;
    }
    return t;
  }

  /// Prefer [describe]; otherwise a generic fallback (no raw stack / URLs in UI).
  static String fullUserMessage(Object error) {
    final d = describe(error);
    if (d != null) return '${d.title}\n\n${d.message}';
    return 'Something went wrong. Please try again.\n\n'
        'If this keeps happening, check your internet connection.';
  }

  static bool looksLikeNetwork(Object error) => describe(error) != null;
}
