import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/domain/models/notification_model.dart';

/// Handler for background messages - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
  }
  // Save notification to storage for later retrieval
  await NotificationService.instance.saveNotificationToStorage(message);
}

/// Professional Notification Service for Firebase Cloud Messaging
class NotificationService extends GetxService {
  static NotificationService get instance => Get.find<NotificationService>();
  
  // Firebase Messaging instance
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Observable states
  final RxString fcmToken = ''.obs;
  final RxBool isInitialized = false.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  
  // Notification channel settings
  static const String _channelId = 'hesabati_notifications';
  static const String _channelName = 'Hesabati Notifications';
  static const String _channelDescription = 'Notifications for Hesabati App';
  
  // Storage key
  static const String _storageKey = 'saved_notifications';
  
  /// Initialize the notification service
  Future<NotificationService> init() async {
    try {
      // Request permission
      await _requestPermission();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM Token
      await _getFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Load saved notifications
      await loadSavedNotifications();
      
      isInitialized.value = true;
      
      if (kDebugMode) {
        debugPrint('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing NotificationService: $e');
      }
    }
    
    return this;
  }
  
  /// Request notification permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    }
  }
  
  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }
  
  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  
  /// Get FCM Token
  Future<void> _getFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        fcmToken.value = token;
        if (kDebugMode) {
          debugPrint('FCM Token: $token');
        }
        // Save token to Firestore for the current user
        await _saveTokenToFirestore(token);
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        _saveTokenToFirestore(newToken);
        if (kDebugMode) {
          debugPrint('FCM Token refreshed: $newToken');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting FCM token: $e');
      }
    }
  }
  
  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    // This will be connected to your user service
    // await FirebaseService.instance.updateUserFCMToken(token);
  }
  
  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    _checkInitialMessage();
  }
  
  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Foreground message received: ${message.notification?.title}');
    }
    
    // Save notification
    await saveNotificationToStorage(message);
    
    // Show local notification
    await _showLocalNotification(message);
    
    // Update unread count
    unreadCount.value++;
  }
  
  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Hesabati',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${message.notification?.title}');
    }
    
    // Navigate based on notification data
    _navigateFromNotification(message.data);
  }
  
  /// Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateFromNotification(data);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing notification payload: $e');
        }
      }
    }
  }
  
  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    String? type = data['type'];
    // String? id = data['id']; // Can be used for specific navigation
    
    switch (type) {
      case 'transaction':
        // Navigate to transaction details
        // Get.to(() => TransactionDetailsScreen(transactionId: id));
        break;
      case 'sync':
        // Navigate to sync screen
        // Get.to(() => SyncScreen());
        break;
      case 'account':
        // Navigate to account details
        // Get.to(() => AccountDetailsScreen(accountId: id));
        break;
      default:
        // Navigate to notifications screen
        Get.toNamed('/notifications');
        break;
    }
  }
  
  /// Check if app was opened from a notification
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  /// Save notification to local storage
  Future<void> saveNotificationToStorage(RemoteMessage message) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing notifications
      List<String> savedNotifications = prefs.getStringList(_storageKey) ?? [];
      
      // Create notification model
      NotificationModel notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Hesabati',
        body: message.notification?.body ?? '',
        data: message.data,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      // Add new notification
      savedNotifications.insert(0, jsonEncode(notification.toJson()));
      
      // Keep only last 100 notifications
      if (savedNotifications.length > 100) {
        savedNotifications = savedNotifications.sublist(0, 100);
      }
      
      // Save back to storage
      await prefs.setStringList(_storageKey, savedNotifications);
      
      // Update local list
      notifications.insert(0, notification);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving notification: $e');
      }
    }
  }
  
  /// Load saved notifications from storage
  Future<void> loadSavedNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedNotifications = prefs.getStringList(_storageKey) ?? [];
      
      notifications.value = savedNotifications.map((json) {
        return NotificationModel.fromJson(jsonDecode(json));
      }).toList();
      
      // Count unread
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading notifications: $e');
      }
    }
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      int index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        
        // Update storage
        await _updateStorage();
        
        // Update unread count
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      
      await _updateStorage();
      unreadCount.value = 0;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking all notifications as read: $e');
      }
    }
  }
  
  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      notifications.removeWhere((n) => n.id == notificationId);
      await _updateStorage();
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
    }
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      notifications.clear();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      unreadCount.value = 0;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing notifications: $e');
      }
    }
  }
  
  /// Update storage with current notifications
  Future<void> _updateStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedNotifications = notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, savedNotifications);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating storage: $e');
      }
    }
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to topic: $e');
      }
    }
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error unsubscribing from topic: $e');
      }
    }
  }
  
  /// Get FCM Token (for sending notifications)
  String getToken() => fcmToken.value;
}
