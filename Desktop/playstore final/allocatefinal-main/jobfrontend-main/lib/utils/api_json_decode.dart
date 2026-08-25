import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// True when the body looks like HTML (common when the API URL is wrong or the
/// server returns nginx/Apache/Laravel error pages instead of JSON).
bool responseBodyLooksLikeHtml(String body) {
  final t = body.trimLeft();
  if (t.isEmpty) return false;
  if (t.startsWith(RegExp(r'<!DOCTYPE', caseSensitive: false))) return true;
  if (t.startsWith(RegExp(r'<html', caseSensitive: false))) return true;
  // Many error pages start with `<` but JSON never does for our APIs.
  if (t.length > 2 && t[0] == '<' && !t.startsWith('{') && !t.startsWith('[')) {
    return true;
  }
  return false;
}

/// Decodes a JSON object from an HTTP response, with a clear error if the server
/// sent HTML (wrong base URL, 404 page, PHP error page, etc.).
Map<String, dynamic> decodeApiJsonObject(http.Response response) {
  final url = response.request?.url.toString() ?? '(unknown URL)';
  final body = response.body;

  if (responseBodyLooksLikeHtml(body)) {
    // Keep details in debug logs only — never show API URLs to users.
    assert(() {
      // ignore: avoid_print
      print(
        '[API] HTML instead of JSON (HTTP ${response.statusCode}) url=$url base=${ApiConfig.baseUrl}',
      );
      return true;
    }());
    throw Exception(
      'Unable to reach JobAllocate right now. Check your internet connection and try again.',
    );
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Expected JSON object, got ${decoded.runtimeType}');
  } on FormatException {
    throw Exception(
      'Unable to load data right now. Check your internet connection and try again.',
    );
  }
}
