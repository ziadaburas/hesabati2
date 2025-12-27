import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/domain/entities/entities.dart';
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
  
  List<NotificationEntity> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'طلبات الحسابات'),
            Tab(text: 'العمليات'),
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
                ],
              ),
            ),
    );
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
    for (final notification in _notifications.where((n) => !n.isRead)) {
      await _firebaseService.markNotificationAsRead(notification.notificationId);
    }
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
