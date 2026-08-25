import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';

/// Model for an individual in-app notification.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final String? type;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
    );
  }
}

/// API client for the notification inbox endpoints.
class NotificationApiService {
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${AppSession.token ?? ''}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<AppNotification>> fetchNotifications({int page = 1}) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications?page=$page'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = decodeApiJsonObject(response);
        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      // Non-fatal — UI will show empty list
    }
    return [];
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = decodeApiJsonObject(response);
        return (decoded['unread_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // ─── Mark Read ─────────────────────────────────────────────────────────────

  Future<void> markOneRead(int notificationId) async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
