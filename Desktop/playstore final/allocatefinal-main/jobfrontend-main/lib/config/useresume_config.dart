class UseresumeConfig {
  UseresumeConfig._();

  /// Your Useresume AI API Key.
  /// Get it from: https://useresume.ai/account/api-platform
  static const String apiKey = String.fromEnvironment(
    'USERESUME_API_KEY',
    defaultValue: 'ur_live_placeholder_rotate_key', 
  );

  /// API Base URL (v3)
  static const String baseUrl = 'https://useresume.ai/api/v3';
}
