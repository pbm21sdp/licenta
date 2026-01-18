import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message: ${message.messageId}');
}

/// Service for managing Firebase Cloud Messaging (FCM) push notifications
/// Handles token registration, refresh, and syncing with Supabase database
class FCMService {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _client = Supabase.instance.client;
  String? _currentToken;

  /// Initialize FCM and set up handlers
  /// Call this after Firebase.initializeApp() and user login
  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions (Android 13+)
    await _requestPermission();

    // Set up foreground notification handling
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
    return isAuthorized;
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground message: ${message.notification?.title}');
    // The notification will be shown automatically if foreground options are set
  }

  /// Handle notification tap when app is in background/terminated
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM Notification tapped: ${message.data}');
    // TODO: Navigate to relevant screen based on message.data
    // For example, navigate to application details if message contains application_id
  }

  /// Called when FCM token is refreshed
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('FCM token refreshed');
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _saveTokenToDatabase(userId, newToken);
    }
  }

  /// Register FCM token for the current user
  /// Call this after user login
  Future<void> registerToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToDatabase(userId, token);
        debugPrint('FCM token registered for user: $userId');
      }
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Save FCM token to database
  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      // Upsert token - update if exists, insert if new
      await _client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
    } catch (e) {
      debugPrint('Failed to save FCM token to database: $e');
    }
  }

  /// Remove FCM token from database
  /// Call this on user logout
  Future<void> unregisterToken(String userId) async {
    try {
      if (_currentToken != null) {
        await _client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', _currentToken!);
        _currentToken = null;
        debugPrint('FCM token unregistered for user: $userId');
      }
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  /// Update push notification preference in database
  /// This enables/disables push notifications server-side
  Future<void> setPushEnabled(String userId, bool enabled) async {
    try {
      await _client
          .from('user_profiles')
          .update({'push_notifications_enabled': enabled})
          .eq('id', userId);

      if (enabled) {
        // Re-register token when enabling
        await registerToken(userId);
      } else {
        // Remove token when disabling
        await unregisterToken(userId);
      }

      debugPrint('Push notifications ${enabled ? 'enabled' : 'disabled'} for user: $userId');
    } catch (e) {
      debugPrint('Failed to update push preference: $e');
      rethrow;
    }
  }

  /// Get current push notification preference from database
  Future<bool> getPushEnabled(String userId) async {
    try {
      final result = await _client
          .from('user_profiles')
          .select('push_notifications_enabled')
          .eq('id', userId)
          .maybeSingle();

      return result?['push_notifications_enabled'] ?? true;
    } catch (e) {
      debugPrint('Failed to get push preference: $e');
      return true; // Default to enabled
    }
  }

  /// Get current FCM token (for debugging)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
