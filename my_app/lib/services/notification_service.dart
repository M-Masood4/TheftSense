import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');

  if (message.notification != null) {
    debugPrint('Message notification: ${message.notification?.title}');
  }
}

/// Android notification channel for high importance notifications
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for shoplifting alerts',
  importance: Importance.max,
);

/// Service for handling Firebase Cloud Messaging push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Stream controller for notification events
  final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground messages
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications for Android foreground display
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message in foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Notification Title: ${message.notification?.title}');
          debugPrint('Notification Body: ${message.notification?.body}');

          // Show local notification on Android when app is in foreground
          if (!kIsWeb) {
            _showLocalNotification(message);
          }
        }

        _onMessageController.add(message);
      });

      // Handle when app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification: ${message.messageId}');
        _onMessageController.add(message);
      });

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state with message');
        _onMessageController.add(initialMessage);
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications plugin for Android
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    debugPrint('Local notifications initialized');
  }

  /// Show a local notification (for foreground messages on Android)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Shoplifting Alert',
      notification.body ?? 'Suspicious activity detected',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Request permission for push notifications
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('Notification permission: ${settings.authorizationStatus}');

      if (granted) {
        await _getToken();
      }

      return granted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get the FCM token for this device
  Future<String?> _getToken() async {
    try {
      // For web, you need a VAPID key from Firebase Console
      // Go to: Project Settings -> Cloud Messaging -> Web Push certificates
      if (kIsWeb) {
        _fcmToken = await _messaging.getToken(
          // Replace with your VAPID key from Firebase Console
          vapidKey:
              'BC0sZ1ygzCri2m2Y8tjhZZYLOmQl17vgfGErs76y24BT4Yu5p8YGStFUdE5s3ymzKJLi1PzBEmM-S0nFERnrWhY',
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      debugPrint('FCM Token: $_fcmToken');

      // Save token to local storage for persistence
      await _saveTokenToStorage(_fcmToken);

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveTokenToStorage(newToken);
      });

      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save the FCM token to local storage (web only - mobile tokens are managed by FCM)
  Future<void> _saveTokenToStorage(String? token) async {
    if (token == null || !kIsWeb) return;

    try {
      final factory = getIdbFactory();
      final db = await factory!.open(
        'user_settings',
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.database;
          if (!db.objectStoreNames.contains('settings')) {
            db.createObjectStore('settings', keyPath: 'key');
          }
        },
      );

      final txn = db.transaction('settings', idbModeReadWrite);
      final store = txn.objectStore('settings');

      await store.put({'key': 'fcmToken', 'value': token});

      await txn.completed;
      debugPrint('FCM token saved to storage');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get the saved FCM token from storage (web only)
  Future<String?> getSavedToken() async {
    // On mobile, return current token from memory or get fresh one
    if (!kIsWeb) {
      return _fcmToken;
    }

    try {
      final factory = getIdbFactory();
      final db = await factory!.open(
        'user_settings',
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.database;
          if (!db.objectStoreNames.contains('settings')) {
            db.createObjectStore('settings', keyPath: 'key');
          }
        },
      );

      final txn = db.transaction('settings', idbModeReadOnly);
      final store = txn.objectStore('settings');
      final result = await store.getObject('fcmToken');
      await txn.completed;

      if (result != null) {
        return (result as Map)['value'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting saved FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get current notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Delete the FCM token (for logout or disabling notifications)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _onMessageController.close();
  }
}
