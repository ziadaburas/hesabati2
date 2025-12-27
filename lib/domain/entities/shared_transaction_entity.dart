import '/core/constants/app_constants.dart';

/// كيان العملية المشتركة - يمثل عملية مالية في حساب مشترك
/// الحالات:
/// - offline: تم إنشاؤها محلياً ولم يتم إرسالها بعد (لا يوجد اتصال)
/// - pending_approval: تم إرسالها وبانتظار موافقة الطرف الآخر
/// - approved: تمت الموافقة عليها وأصبحت عملية معتمدة
/// - rejected: تم رفضها من الطرف الآخر
class SharedTransactionEntity {
  final String transactionId;
  final String accountId;           // معرف الحساب المشترك
  final String linkedAccountId;     // معرف الحساب المرتبط للطرف الآخر
  final double amount;
  final String transactionType;     // in, out
  final String description;
  final String? notes;
  final DateTime transactionDate;
  final String createdByUserId;     // المستخدم الذي أنشأ العملية
  final String? createdByUserName;  // اسم المستخدم الذي أنشأ العملية
  final String otherPartyUserId;    // الطرف الآخر الذي يجب أن يوافق
  final String? otherPartyUserName; // اسم الطرف الآخر
  final String sharedStatus;        // offline, pending_approval, approved, rejected
  final String? approvedByUserId;   // من وافق على العملية
  final DateTime? approvedAt;       // وقت الموافقة
  final String? rejectionReason;    // سبب الرفض إن وجد
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;              // هل تمت المزامنة مع Firebase

  const SharedTransactionEntity({
    required this.transactionId,
    required this.accountId,
    required this.linkedAccountId,
    required this.amount,
    required this.transactionType,
    required this.description,
    this.notes,
    required this.transactionDate,
    required this.createdByUserId,
    this.createdByUserName,
    required this.otherPartyUserId,
    this.otherPartyUserName,
    required this.sharedStatus,
    this.approvedByUserId,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// نسخ الكيان مع تعديل بعض الحقول
  SharedTransactionEntity copyWith({
    String? transactionId,
    String? accountId,
    String? linkedAccountId,
    double? amount,
    String? transactionType,
    String? description,
    String? notes,
    DateTime? transactionDate,
    String? createdByUserId,
    String? createdByUserName,
    String? otherPartyUserId,
    String? otherPartyUserName,
    String? sharedStatus,
    String? approvedByUserId,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return SharedTransactionEntity(
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUserName: createdByUserName ?? this.createdByUserName,
      otherPartyUserId: otherPartyUserId ?? this.otherPartyUserId,
      otherPartyUserName: otherPartyUserName ?? this.otherPartyUserName,
      sharedStatus: sharedStatus ?? this.sharedStatus,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات المحلية
  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'account_id': accountId,
      'linked_account_id': linkedAccountId,
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'created_by_user_id': createdByUserId,
      'created_by_user_name': createdByUserName,
      'other_party_user_id': otherPartyUserId,
      'other_party_user_name': otherPartyUserName,
      'shared_status': sharedStatus,
      'approved_by_user_id': approvedByUserId,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// إنشاء من Map من قاعدة البيانات المحلية
  factory SharedTransactionEntity.fromMap(Map<String, dynamic> map) {
    return SharedTransactionEntity(
      transactionId: map['transaction_id'] as String,
      accountId: map['account_id'] as String,
      linkedAccountId: map['linked_account_id'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      transactionType: map['transaction_type'] as String,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      createdByUserId: map['created_by_user_id'] as String,
      createdByUserName: map['created_by_user_name'] as String?,
      otherPartyUserId: map['other_party_user_id'] as String,
      otherPartyUserName: map['other_party_user_name'] as String?,
      sharedStatus: map['shared_status'] as String? ?? AppConstants.sharedTransactionStatusOffline,
      approvedByUserId: map['approved_by_user_id'] as String?,
      approvedAt: map['approved_at'] != null 
          ? DateTime.parse(map['approved_at'] as String) 
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  /// تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'accountId': accountId,
      'linkedAccountId': linkedAccountId,
      'amount': amount,
      'transactionType': transactionType,
      'description': description,
      'notes': notes,
      'transactionDate': transactionDate.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'otherPartyUserId': otherPartyUserId,
      'otherPartyUserName': otherPartyUserName,
      'sharedStatus': sharedStatus,
      'approvedByUserId': approvedByUserId,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء من Firestore
  factory SharedTransactionEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return SharedTransactionEntity(
      transactionId: docId,
      accountId: map['accountId'] as String? ?? '',
      linkedAccountId: map['linkedAccountId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: map['transactionType'] as String? ?? AppConstants.transactionTypeIn,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String?,
      transactionDate: map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'] as String)
          : DateTime.now(),
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdByUserName: map['createdByUserName'] as String?,
      otherPartyUserId: map['otherPartyUserId'] as String? ?? '',
      otherPartyUserName: map['otherPartyUserName'] as String?,
      sharedStatus: map['sharedStatus'] as String? ?? AppConstants.sharedTransactionStatusPendingApproval,
      approvedByUserId: map['approvedByUserId'] as String?,
      approvedAt: map['approvedAt'] != null
          ? DateTime.parse(map['approvedAt'] as String)
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: true,
    );
  }

  // ============ Helper Getters ============

  /// هل العملية واردة؟
  bool get isIncoming => transactionType == AppConstants.transactionTypeIn;

  /// هل العملية صادرة؟
  bool get isOutgoing => transactionType == AppConstants.transactionTypeOut;

  /// هل العملية أوفلاين (لم يتم إرسالها)؟
  bool get isOffline => sharedStatus == AppConstants.sharedTransactionStatusOffline;

  /// هل العملية بانتظار الموافقة؟
  bool get isPendingApproval => sharedStatus == AppConstants.sharedTransactionStatusPendingApproval;

  /// هل العملية معتمدة؟
  bool get isApproved => sharedStatus == AppConstants.sharedTransactionStatusApproved;

  /// هل العملية مرفوضة؟
  bool get isRejected => sharedStatus == AppConstants.sharedTransactionStatusRejected;

  /// الحصول على تسمية نوع العملية
  String get transactionTypeLabel {
    switch (transactionType) {
      case AppConstants.transactionTypeIn:
        return 'وارد';
      case AppConstants.transactionTypeOut:
        return 'صادر';
      default:
        return transactionType;
    }
  }

  /// الحصول على تسمية حالة العملية المشتركة
  String get sharedStatusLabel {
    switch (sharedStatus) {
      case AppConstants.sharedTransactionStatusOffline:
        return 'أوفلاين';
      case AppConstants.sharedTransactionStatusPendingApproval:
        return 'بانتظار الموافقة';
      case AppConstants.sharedTransactionStatusApproved:
        return 'معتمدة';
      case AppConstants.sharedTransactionStatusRejected:
        return 'مرفوضة';
      default:
        return sharedStatus;
    }
  }

  @override
  String toString() {
    return 'SharedTransactionEntity(transactionId: $transactionId, accountId: $accountId, amount: $amount, status: $sharedStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedTransactionEntity && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}
