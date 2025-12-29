import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/data/services/notification_service.dart';
import '/domain/entities/entities.dart';
import '/domain/models/notification_model.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة الإشعارات
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Get NotificationController if available
  NotificationController? get _notificationController {
    try {
      return Get.find<NotificationController>();
    } catch (e) {
      return null;
    }
  }
  
  List<NotificationEntity> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authController.currentUserId;
      _notifications = await _firebaseService.getUserNotifications(userId);
      
      // Also refresh FCM notifications
      _notificationController?.refreshNotifications();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل الإشعارات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<NotificationEntity> get _allNotifications => _notifications;

  List<NotificationEntity> get _accountRequestNotifications =>
      _notifications.where((n) => n.notificationType == AppConstants.notificationTypeAccountRequest).toList();

  List<NotificationEntity> get _transactionNotifications =>
      _notifications.where((n) => n.notificationType == AppConstants.notificationTypeTransactionUpdate).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // FCM Token copy button (for testing)
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ FCM Token',
            onPressed: _copyFCMToken,
          ),
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'قراءة الكل',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'طلبات الحسابات'),
            Tab(text: 'العمليات'),
            Tab(text: 'إشعارات Push'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsList(_allNotifications),
                  _buildNotificationsList(_accountRequestNotifications),
                  _buildNotificationsList(_transactionNotifications),
                  _buildPushNotificationsList(),
                ],
              ),
            ),
    );
  }
  
  /// Copy FCM Token for testing
  void _copyFCMToken() {
    final token = _notificationController?.getToken() ?? '';
    if (token.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: token));
      Get.snackbar(
        'تم النسخ',
        'تم نسخ FCM Token للاستخدام في اختبار الإشعارات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'تنبيه',
        'لم يتم تهيئة خدمة الإشعارات بعد',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    }
  }
  
  /// Build Push Notifications List (FCM)
  Widget _buildPushNotificationsList() {
    final controller = _notificationController;
    
    if (controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'خدمة الإشعارات غير متوفرة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Obx(() {
      final pushNotifications = controller.notifications;
      
      if (pushNotifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'لا توجد إشعارات Push',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildFCMTokenInfo(),
            ],
          ),
        );
      }
      
      return Column(
        children: [
          // FCM Token info card
          _buildFCMTokenInfo(),
          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pushNotifications.length,
              itemBuilder: (context, index) {
                return _buildPushNotificationCard(pushNotifications[index]);
              },
            ),
          ),
        ],
      );
    });
  }
  
  /// FCM Token info widget
  Widget _buildFCMTokenInfo() {
    final controller = _notificationController;
    if (controller == null) return const SizedBox.shrink();
    
    return Obx(() {
      final token = controller.fcmToken.value;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'FCM Token (للاختبار)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyFCMToken,
                  color: AppColors.primary,
                  tooltip: 'نسخ',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              token.isEmpty ? 'جاري التحميل...' : '${token.substring(0, token.length > 50 ? 50 : token.length)}...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }
  
  /// Build Push Notification Card
  Widget _buildPushNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _notificationController?.deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
        child: InkWell(
          onTap: () => _onPushNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  child: const Icon(
                    Icons.notifications_active,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.formattedTime,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Handle push notification tap
  void _onPushNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationController?.markAsRead(notification.id);
    }
  }

  Widget _buildNotificationsList(List<NotificationEntity> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
    final Color typeColor = _getNotificationTypeColor(notification.notificationType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة النوع
              CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.1),
                child: Icon(
                  _getNotificationTypeIcon(notification.notificationType),
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case AppConstants.notificationTypeAccountRequest:
        return AppColors.shared;
      case AppConstants.notificationTypeTransactionUpdate:
        return AppColors.success;
      case AppConstants.notificationTypeSyncStatus:
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case AppConstants.notificationTypeAccountRequest:
        return Icons.people;
      case AppConstants.notificationTypeTransactionUpdate:
        return Icons.receipt_long;
      case AppConstants.notificationTypeSyncStatus:
        return Icons.sync;
      default:
        return Icons.notifications;
    }
  }

  void _onNotificationTap(NotificationEntity notification) async {
    // تعليم كمقروء
    if (!notification.isRead) {
      await _firebaseService.markNotificationAsRead(notification.notificationId);
      await _loadNotifications();
    }

    // التنقل حسب نوع الإشعار
    if (notification.relatedAccountId != null) {
      // فتح تفاصيل الحساب
    } else if (notification.relatedRequestId != null) {
      // فتح الطلب
    }
  }

  void _markAllAsRead() async {
    // Mark Firebase notifications as read
    for (final notification in _notifications.where((n) => !n.isRead)) {
      await _firebaseService.markNotificationAsRead(notification.notificationId);
    }
    
    // Mark FCM/Push notifications as read
    _notificationController?.markAllAsRead();
    
    await _loadNotifications();
    
    Get.snackbar(
      'نجح',
      'تم تعليم جميع الإشعارات كمقروءة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}
