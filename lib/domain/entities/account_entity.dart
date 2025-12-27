import '/core/constants/app_constants.dart';

/// كيان الحساب - يمثل حساب في التطبيق
class AccountEntity {
  final String accountId;
  final String userId;
  final String accountName;
  final String accountType; // loan, debt, savings, shared
  final String accountCategory; // local, shared
  final double balance;
  final String currency;
  final String? otherPartyId;
  final String? otherPartyName;
  final String accountStatus; // active, pending, closed
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String syncStatus;

  const AccountEntity({
    required this.accountId,
    required this.userId,
    required this.accountName,
    required this.accountType,
    required this.accountCategory,
    this.balance = 0.0,
    this.currency = 'SAR',
    this.otherPartyId,
    this.otherPartyName,
    required this.accountStatus,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncStatus = 'offline',
  });

  /// نسخ الكيان مع تعديل بعض الحقول
  AccountEntity copyWith({
    String? accountId,
    String? userId,
    String? accountName,
    String? accountType,
    String? accountCategory,
    double? balance,
    String? currency,
    String? otherPartyId,
    String? otherPartyName,
    String? accountStatus,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? syncStatus,
  }) {
    return AccountEntity(
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      accountCategory: accountCategory ?? this.accountCategory,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      otherPartyId: otherPartyId ?? this.otherPartyId,
      otherPartyName: otherPartyName ?? this.otherPartyName,
      accountStatus: accountStatus ?? this.accountStatus,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'user_id': userId,
      'account_name': accountName,
      'account_type': accountType,
      'account_category': accountCategory,
      'balance': balance,
      'currency': currency,
      'other_party_id': otherPartyId,
      'other_party_name': otherPartyName,
      'account_status': accountStatus,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus,
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory AccountEntity.fromMap(Map<String, dynamic> map) {
    return AccountEntity(
      accountId: map['account_id'] as String,
      userId: map['user_id'] as String,
      accountName: map['account_name'] as String,
      accountType: map['account_type'] as String,
      accountCategory: map['account_category'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? AppConstants.defaultCurrency,
      otherPartyId: map['other_party_id'] as String?,
      otherPartyName: map['other_party_name'] as String?,
      accountStatus: map['account_status'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
      syncStatus: map['sync_status'] as String? ?? AppConstants.syncStatusOffline,
    );
  }

  /// تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'userId': userId,
      'accountName': accountName,
      'accountType': accountType,
      'accountCategory': accountCategory,
      'balance': balance,
      'currency': currency,
      'otherPartyId': otherPartyId,
      'otherPartyName': otherPartyName,
      'accountStatus': accountStatus,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء من Firestore
  factory AccountEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return AccountEntity(
      accountId: docId,
      userId: map['userId'] as String? ?? '',
      accountName: map['accountName'] as String? ?? '',
      accountType: map['accountType'] as String? ?? AppConstants.accountTypeLoan,
      accountCategory: map['accountCategory'] as String? ?? AppConstants.accountCategoryLocal,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? AppConstants.defaultCurrency,
      otherPartyId: map['otherPartyId'] as String?,
      otherPartyName: map['otherPartyName'] as String?,
      accountStatus: map['accountStatus'] as String? ?? AppConstants.accountStatusActive,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: true,
      syncStatus: AppConstants.syncStatusSynced,
    );
  }

  /// الحصول على لون نوع الحساب
  String get accountTypeLabel {
    switch (accountType) {
      case AppConstants.accountTypeLoan:
        return 'دين';
      case AppConstants.accountTypeDebt:
        return 'مديونية';
      case AppConstants.accountTypeSavings:
        return 'توفير';
      case AppConstants.accountTypeShared:
        return 'مشترك';
      default:
        return accountType;
    }
  }

  /// الحصول على تسمية حالة الحساب
  String get accountStatusLabel {
    switch (accountStatus) {
      case AppConstants.accountStatusActive:
        return 'نشط';
      case AppConstants.accountStatusPending:
        return 'معلق';
      case AppConstants.accountStatusClosed:
        return 'مغلق';
      default:
        return accountStatus;
    }
  }

  @override
  String toString() {
    return 'AccountEntity(accountId: $accountId, accountName: $accountName, balance: $balance, accountType: $accountType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountEntity && other.accountId == accountId;
  }

  @override
  int get hashCode => accountId.hashCode;
}
