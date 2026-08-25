import 'package:flutter/services.dart';

/// Wrapper around the native `com.joballocate.in/secure` MethodChannel
/// that sets / clears Android FLAG_SECURE to block screenshots and screen recordings.
///
/// Safe to call on non-Android platforms — errors are silently swallowed.
class ScreenshotProtection {
  static const _channel = MethodChannel('com.joballocate.in/secure');

  /// Prevents screenshots and screen recording on the current window.
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<bool>('enableSecure');
    } catch (_) {}
  }

  /// Removes the screenshot restriction from the current window.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<bool>('disableSecure');
    } catch (_) {}
  }
}
