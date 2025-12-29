import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '/data/services/notification_service.dart';
import '/domain/models/notification_model.dart';

/// Controller for managing notification state and UI interactions
class NotificationController extends GetxController {
  static NotificationController get instance => Get.find<NotificationController>();
  
  // Get notification service
  NotificationService get _notificationService => NotificationService.instance;
  
  // Observable states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Getters for notification data
  RxList<NotificationModel> get notifications => _notificationService.notifications;
  RxInt get unreadCount => _notificationService.unreadCount;
  RxString get fcmToken => _notificationService.fcmToken;
  RxBool get isInitialized => _notificationService.isInitialized;
  
  @override
  void onInit() {
    super.onInit();
    // داخل NotificationService
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // إنشاء مودل جديد من الرسالة القادمة
        final newNotification = NotificationModel(
          id: message.messageId ?? DateTime.now().toString(),
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          isRead: false, timestamp: DateTime.now(),
        );

        // إضافة الإشعار للقائمة التي يراقبها الكنترولر
        notifications.insert(0, newNotification); 
        
        // تحديث عدد الإشعارات غير المقروءة تلقائياً
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    });
    if (kDebugMode) {
      debugPrint('NotificationController initialized');
    }
  }
  
  /// Refresh notifications
  Future<void> refreshNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _notificationService.loadSavedNotifications();
    } catch (e) {
      errorMessage.value = 'فشل في تحديث الإشعارات';
      if (kDebugMode) {
        debugPrint('Error refreshing notifications: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      errorMessage.value = 'فشل في تحديث حالة الإشعار';
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      isLoading.value = true;
      await _notificationService.markAllAsRead();
      Get.snackbar(
        'تم',
        'تم تحديد جميع الإشعارات كمقروءة',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'فشل في تحديث الإشعارات';
      if (kDebugMode) {
        debugPrint('Error marking all as read: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      Get.snackbar(
        'تم',
        'تم حذف الإشعار',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'فشل في حذف الإشعار';
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
    }
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      isLoading.value = true;
      await _notificationService.clearAllNotifications();
      Get.snackbar(
        'تم',
        'تم حذف جميع الإشعارات',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'فشل في حذف الإشعارات';
      if (kDebugMode) {
        debugPrint('Error clearing notifications: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
      Get.snackbar(
        'تم',
        'تم الاشتراك في $topic',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'فشل في الاشتراك';
      if (kDebugMode) {
        debugPrint('Error subscribing to topic: $e');
      }
    }
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
      Get.snackbar(
        'تم',
        'تم إلغاء الاشتراك من $topic',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'فشل في إلغاء الاشتراك';
      if (kDebugMode) {
        debugPrint('Error unsubscribing from topic: $e');
      }
    }
  }
  
  /// Get FCM Token for testing
  String getToken() => fcmToken.value;
  
  /// Copy token to clipboard
  void copyTokenToClipboard() {
    if (fcmToken.value.isNotEmpty) {
      // Clipboard.setData(ClipboardData(text: fcmToken.value));
      Get.snackbar(
        'تم النسخ',
        'تم نسخ FCM Token',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
