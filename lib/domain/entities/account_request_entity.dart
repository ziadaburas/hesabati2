import '/core/constants/app_constants.dart';

/// كيان طلب فتح حساب مشترك
class AccountRequestEntity {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String accountName;
  final String accountType;
  final String requestStatus; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseNotes;
  final bool isSynced;

  // بيانات إضافية للعرض
  final String? fromUserName;
  final String? toUserName;
  final String? fromUserEmail;
  final String? toUserEmail;

  const AccountRequestEntity({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.accountName,
    required this.accountType,
    required this.requestStatus,
    required this.createdAt,
    this.respondedAt,
    this.responseNotes,
    this.isSynced = false,
    this.fromUserName,
    this.toUserName,
    this.fromUserEmail,
    this.toUserEmail,
  });

  /// نسخ الكيان مع تعديل بعض الحقول
  AccountRequestEntity copyWith({
    String? requestId,
    String? fromUserId,
    String? toUserId,
    String? accountName,
    String? accountType,
    String? requestStatus,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseNotes,
    bool? isSynced,
    String? fromUserName,
    String? toUserName,
    String? fromUserEmail,
    String? toUserEmail,
  }) {
    return AccountRequestEntity(
      requestId: requestId ?? this.requestId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      requestStatus: requestStatus ?? this.requestStatus,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseNotes: responseNotes ?? this.responseNotes,
      isSynced: isSynced ?? this.isSynced,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      toUserEmail: toUserEmail ?? this.toUserEmail,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'account_name': accountName,
      'account_type': accountType,
      'request_status': requestStatus,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response_notes': responseNotes,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory AccountRequestEntity.fromMap(Map<String, dynamic> map) {
    return AccountRequestEntity(
      requestId: map['request_id'] as String,
      fromUserId: map['from_user_id'] as String,
      toUserId: map['to_user_id'] as String,
      accountName: map['account_name'] as String,
      accountType: map['account_type'] as String,
      requestStatus: map['request_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
      responseNotes: map['response_notes'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  /// تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'accountName': accountName,
      'accountType': accountType,
      'requestStatus': requestStatus,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'responseNotes': responseNotes,
    };
  }

  /// إنشاء من Firestore
  factory AccountRequestEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return AccountRequestEntity(
      requestId: docId,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      accountName: map['accountName'] as String? ?? '',
      accountType: map['accountType'] as String? ?? AppConstants.accountTypeLoan,
      requestStatus: map['requestStatus'] as String? ?? AppConstants.requestStatusPending,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'] as String)
          : null,
      responseNotes: map['responseNotes'] as String?,
      isSynced: true,
      fromUserName: map['fromUserName'] as String?,
      toUserName: map['toUserName'] as String?,
      fromUserEmail: map['fromUserEmail'] as String?,
      toUserEmail: map['toUserEmail'] as String?,
    );
  }

  /// هل الطلب معلق؟
  bool get isPending => requestStatus == AppConstants.requestStatusPending;

  /// هل الطلب مقبول؟
  bool get isAccepted => requestStatus == AppConstants.requestStatusAccepted;

  /// هل الطلب مرفوض؟
  bool get isRejected => requestStatus == AppConstants.requestStatusRejected;

  /// الحصول على تسمية حالة الطلب
  String get statusLabel {
    switch (requestStatus) {
      case AppConstants.requestStatusPending:
        return 'معلق';
      case AppConstants.requestStatusAccepted:
        return 'مقبول';
      case AppConstants.requestStatusRejected:
        return 'مرفوض';
      default:
        return requestStatus;
    }
  }

  @override
  String toString() {
    return 'AccountRequestEntity(requestId: $requestId, fromUserId: $fromUserId, toUserId: $toUserId, status: $requestStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountRequestEntity && other.requestId == requestId;
  }

  @override
  int get hashCode => requestId.hashCode;
}
