import '/core/constants/app_constants.dart';

/// كيان الإشعار
class NotificationEntity {
  final String notificationId;
  final String userId;
  final String notificationType;
  final String title;
  final String body;
  final String? relatedAccountId;
  final String? relatedRequestId;
  final bool isRead;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.notificationId,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.relatedAccountId,
    this.relatedRequestId,
    this.isRead = false,
    this.isDeleted = false,
    required this.createdAt,
    this.readAt,
  });

  /// نسخ الكيان مع تعديل بعض الحقول
  NotificationEntity copyWith({
    String? notificationId,
    String? userId,
    String? notificationType,
    String? title,
    String? body,
    String? relatedAccountId,
    String? relatedRequestId,
    bool? isRead,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedAccountId: relatedAccountId ?? this.relatedAccountId,
      relatedRequestId: relatedRequestId ?? this.relatedRequestId,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'body': body,
      'related_account_id': relatedAccountId,
      'related_request_id': relatedRequestId,
      'is_read': isRead ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      notificationId: map['notification_id'] as String,
      userId: map['user_id'] as String,
      notificationType: map['notification_type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      relatedAccountId: map['related_account_id'] as String?,
      relatedRequestId: map['related_request_id'] as String?,
      isRead: (map['is_read'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
    );
  }

  /// تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'notificationType': notificationType,
      'title': title,
      'body': body,
      'relatedAccountId': relatedAccountId,
      'relatedRequestId': relatedRequestId,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// إنشاء من Firestore
  factory NotificationEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return NotificationEntity(
      notificationId: docId,
      userId: map['userId'] as String? ?? '',
      notificationType: map['notificationType'] as String? ?? AppConstants.notificationTypeSyncStatus,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      relatedAccountId: map['relatedAccountId'] as String?,
      relatedRequestId: map['relatedRequestId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
    );
  }

  /// الحصول على تسمية نوع الإشعار
  String get notificationTypeLabel {
    switch (notificationType) {
      case AppConstants.notificationTypeAccountRequest:
        return 'طلب حساب';
      case AppConstants.notificationTypeTransactionUpdate:
        return 'تحديث عملية';
      case AppConstants.notificationTypeSyncStatus:
        return 'حالة المزامنة';
      default:
        return notificationType;
    }
  }

  @override
  String toString() {
    return 'NotificationEntity(notificationId: $notificationId, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationEntity && other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;
}
