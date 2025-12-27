import '/core/constants/app_constants.dart';

/// كيان المستخدم - يمثل بيانات المستخدم في التطبيق
class UserEntity {
  final String userId;
  final String username;
  final String email;
  final String? phone;
  final String? profilePictureUrl;
  final String userType; // local, authenticated
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const UserEntity({
    required this.userId,
    required this.username,
    required this.email,
    this.phone,
    this.profilePictureUrl,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// إنشاء مستخدم محلي افتراضي
  factory UserEntity.localUser() {
    final now = DateTime.now();
    return UserEntity(
      userId: 'local_user',
      username: 'مستخدم محلي',
      email: '',
      userType: AppConstants.userTypeLocal,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  /// نسخ الكيان مع تعديل بعض الحقول
  UserEntity copyWith({
    String? userId,
    String? username,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_picture_url': profilePictureUrl,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      userId: map['user_id'] as String,
      username: map['username'] as String,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      userType: map['user_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  /// تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'userType': userType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء من Firestore
  factory UserEntity.fromFirestore(Map<String, dynamic> map, String docId) {
    return UserEntity(
      userId: docId,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      profilePictureUrl: map['profilePictureUrl'] as String?,
      userType: map['userType'] as String? ?? AppConstants.userTypeAuthenticated,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: true,
    );
  }

  @override
  String toString() {
    return 'UserEntity(userId: $userId, username: $username, email: $email, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
