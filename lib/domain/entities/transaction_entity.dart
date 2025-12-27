import '/core/constants/app_constants.dart';

/// كيان العملية - يمثل عملية مالية في حساب
class TransactionEntity {
  final String transactionId;
  final String accountId;
  final double amount;
  final String transactionType; // in, out
  final String description;
  final String? notes;
  final DateTime transactionDate;
  final String recordedByUser;
  final String? approvedByUser;
  final String status; // pending, completed, rejected
  final String transactionStatus; // offline, synced
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const TransactionEntity({
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.transactionType,
    required this.description,
    this.notes,
    required this.transactionDate,
    required this.recordedByUser,
    this.approvedByUser,
    required this.status,
    this.transactionStatus = 'offline',
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// نسخ الكيان مع تعديل بعض الحقول
  TransactionEntity copyWith({
    String? transactionId,
    String? accountId,
    double? amount,
    String? transactionType,
    String? description,
    String? notes,
    DateTime? transactionDate,
    String? recordedByUser,
    String? approvedByUser,
    String? status,
    String? transactionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionEntity(
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      recordedByUser: recordedByUser ?? this.recordedByUser,
      approvedByUser: approvedByUser ?? this.approvedByUser,
      status: status ?? this.status,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'account_id': accountId,
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'recorded_by_user': recordedByUser,
      'approved_by_user': approvedByUser,
      'status': status,
      'transaction_status': transactionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      transactionId: map['transaction_id'] as String,
      accountId: map['account_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionType: map['transaction_type'] as String,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      recordedByUser: map['recorded_by_user'] as String,
      approvedByUser: map['approved_by_user'] as String?,
      status: map['status'] as String,
      transactionStatus: map['transaction_status'] as String? ?? AppConstants.syncStatusOffline,
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
      'amount': amount,
      'transactionType': transactionType,
      'description': description,
      'notes': notes,
      'transactionDate': transactionDate.toIso8601String(),
      'recordedByUser': recordedByUser,
      'approvedByUser': approvedByUser,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء من Firestore
  factory TransactionEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return TransactionEntity(
      transactionId: docId,
      accountId: map['accountId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: map['transactionType'] as String? ?? AppConstants.transactionTypeIn,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String?,
      transactionDate: map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'] as String)
          : DateTime.now(),
      recordedByUser: map['recordedByUser'] as String? ?? '',
      approvedByUser: map['approvedByUser'] as String?,
      status: map['status'] as String? ?? AppConstants.transactionStatusCompleted,
      transactionStatus: AppConstants.syncStatusSynced,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: true,
    );
  }

  /// هل العملية واردة؟
  bool get isIncoming => transactionType == AppConstants.transactionTypeIn;

  /// هل العملية صادرة؟
  bool get isOutgoing => transactionType == AppConstants.transactionTypeOut;

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

  /// الحصول على تسمية حالة العملية
  String get statusLabel {
    switch (status) {
      case AppConstants.transactionStatusPending:
        return 'معلق';
      case AppConstants.transactionStatusCompleted:
        return 'مكتمل';
      case AppConstants.transactionStatusRejected:
        return 'مرفوض';
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'TransactionEntity(transactionId: $transactionId, accountId: $accountId, amount: $amount, type: $transactionType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionEntity && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}
