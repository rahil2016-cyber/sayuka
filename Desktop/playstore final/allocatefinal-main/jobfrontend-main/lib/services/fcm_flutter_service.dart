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

/// Firebase Cloud Messaging + system tray notifications.
///
/// Channel id must match backend [FcmService] (`joballocate_default`).
class FcmFlutterService {
  static FcmFlutterService? _instance;
  static FcmFlutterService get instance => _instance ??= FcmFlutterService._();
  FcmFlutterService._();

  bool _initialized = false;
  String? _currentToken;
  final FlutterLocalNotificationsPlugin _localNotifsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Must match Laravel `FcmService` android.notification.channel_id.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'joballocate_default',
    'JobAllocate',
    description: 'Job matches, applications, and account updates.',
    importance: Importance.high,
    playSound: true,
  );

  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FcmFlutterService] Firebase not initialized; skipping.');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

      final androidImplementation = _localNotifsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
        // Android 13+ runtime permission
        await androidImplementation.requestNotificationsPermission();
      }

      // Also create legacy channel id if older app versions used it.
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Legacy channel',
          importance: Importance.high,
        ),
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _currentToken = await messaging.getToken();
      debugPrint('[FcmFlutterService] FCM token: $_currentToken');

      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _sendTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

      // Handle notification tap when app was terminated
      messaging.getInitialMessage().then((initialMessage) {
        if (initialMessage != null) {
          debugPrint('[FcmFlutterService] Terminated app launched from notification: ${initialMessage.data}');
          Future.delayed(const Duration(milliseconds: 1000), () {
            NotificationEvents.notify(initialMessage);
          });
        }
      });

      _initialized = true;

      // Cold start while already logged in — register device for pushes.
      if (AppSession.isLoggedIn) {
        await registerTokenAfterLogin();
      }
    } catch (e, st) {
      debugPrint('[FcmFlutterService] Init error (non-fatal): $e\n$st');
    }
  }

  /// Call after login / session restore so backend can send tray pushes.
  Future<void> registerTokenAfterLogin() async {
    if (!_initialized) {
      // Token may arrive before init finishes; retry getToken.
      try {
        if (Firebase.apps.isNotEmpty) {
          _currentToken ??= await FirebaseMessaging.instance.getToken();
        }
      } catch (_) {}
    }

    var token = _currentToken;
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
        _currentToken = token;
      } catch (_) {}
    }

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
          'device_type':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        }),
      );
      debugPrint('[FcmFlutterService] Token registered: ${response.statusCode}');
    } catch (e) {
      debugPrint('[FcmFlutterService] Token registration error (non-fatal): $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[FcmFlutterService] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _localNotifsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
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
