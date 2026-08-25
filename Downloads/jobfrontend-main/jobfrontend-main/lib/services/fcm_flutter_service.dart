import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'app_session.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await tryInitializeFirebase();
  debugPrint('[FcmFlutterService] Handling a background message: ${message.messageId}');
}

/// Handles Firebase Cloud Messaging (FCM) initialization and token management.
///
/// Gracefully degrades to a no-op when Firebase is not configured (development
/// without google-services.json / GoogleService-Info.plist).
class FcmFlutterService {
  static FcmFlutterService? _instance;
  static FcmFlutterService get instance => _instance ??= FcmFlutterService._();
  FcmFlutterService._();

  bool _initialized = false;
  String? _currentToken;
  final FlutterLocalNotificationsPlugin _localNotifsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    description: 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  String? get currentToken => _currentToken;

  // ─── Initialization ─────────────────────────────────────────────────────────

  /// Called once from [main.dart] after Firebase is initialized.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FcmFlutterService] Firebase not initialized; skipping.');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // Request permissions (iOS; Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint('[FcmFlutterService] Permission: ${settings.authorizationStatus}');

      // Fetch initial token
      _currentToken = await messaging.getToken();
      debugPrint('[FcmFlutterService] FCM token: $_currentToken');

      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[FcmFlutterService] Local notification tapped');
        },
      );

      final androidImplementation = _localNotifsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _sendTokenToServer(newToken);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Background / terminated tap handler
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

      _initialized = true;
    } catch (e, st) {
      debugPrint('[FcmFlutterService] Init error (non-fatal): $e\n$st');
    }
  }

  // ─── Token registration ──────────────────────────────────────────────────────

  /// Call this right after login to register the device token with the backend.
  Future<void> registerTokenAfterLogin() async {
    final token = _currentToken;
    final authToken = AppSession.token;

    if (token == null || token.isEmpty) {
      debugPrint('[FcmFlutterService] No FCM token available to register.');
      return;
    }
    if (authToken == null || authToken.isEmpty) {
      debugPrint('[FcmFlutterService] Not authenticated; skipping token registration.');
      return;
    }

    await _sendTokenToServer(token);
  }

  /// Removes the token from the backend on logout.
  Future<void> unregisterTokenOnLogout() async {
    final token = _currentToken;
    final authToken = AppSession.token;

    if (token == null || authToken == null) return;

    try {
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/device-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      debugPrint('[FcmFlutterService] Token unregister error (non-fatal): $e');
    }
  }

  Future<void> _sendTokenToServer(String fcmToken) async {
    final authToken = AppSession.token;
    if (authToken == null || authToken.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/device-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        }),
      );
      debugPrint('[FcmFlutterService] Token registered: ${response.statusCode}');
    } catch (e) {
      debugPrint('[FcmFlutterService] Token registration error (non-fatal): $e');
    }
  }

  // ─── Message handlers ────────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FcmFlutterService] Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
    
    NotificationEvents.notify(message);
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FcmFlutterService] Notification tapped: ${message.data}');
    NotificationEvents.notify(message);
  }
}

/// Simple event bus so other widgets can react to incoming messages
/// without requiring a full state management solution.
class NotificationEvents {
  static final List<void Function(RemoteMessage)> _listeners = [];

  static void addListener(void Function(RemoteMessage) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(RemoteMessage) listener) {
    _listeners.remove(listener);
  }

  static void notify(RemoteMessage message) {
    for (final l in _listeners) {
      l(message);
    }
  }
}
