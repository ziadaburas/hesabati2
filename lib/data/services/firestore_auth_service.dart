import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// خدمة المصادقة باستخدام Firestore فقط (بدون Firebase Auth)
class FirestoreAuthService {
  static final FirestoreAuthService instance = FirestoreAuthService._init();
  
  FirestoreAuthService._init();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// تشفير كلمة المرور
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من وجود المستخدم بالبريد الإلكتروني
  Future<bool> checkEmailExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Check email exists error: $e');
      }
      return false;
    }
  }

  /// التحقق من وجود اسم المستخدم
  Future<bool> checkUsernameExists(String username) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isEqualTo: username.trim())
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Check username exists error: $e');
      }
      return false;
    }
  }

  /// تسجيل مستخدم جديد
  Future<UserEntity?> registerUser({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // التحقق من عدم وجود البريد الإلكتروني
      if (await checkEmailExists(email)) {
        throw Exception('البريد الإلكتروني مستخدم بالفعل');
      }

      // التحقق من عدم وجود اسم المستخدم
      if (await checkUsernameExists(username)) {
        throw Exception('اسم المستخدم مستخدم بالفعل');
      }

      final userId = const Uuid().v4();
      final now = DateTime.now().toIso8601String();
      final hashedPassword = _hashPassword(password);

      final userData = {
        'userId': userId,
        'username': username.trim(),
        'email': email.toLowerCase().trim(),
        'password': hashedPassword,
        'phone': phone,
        'profilePictureUrl': null,
        'userType': AppConstants.userTypeAuthenticated,
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
        'lastLoginAt': now,
      };

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .set(userData);

      // حفظ بيانات الجلسة
      await _saveSession(userId);

      return UserEntity(
        userId: userId,
        username: username.trim(),
        email: email.toLowerCase().trim(),
        phone: phone,
        userType: AppConstants.userTypeAuthenticated,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Register user error: $e');
      }
      rethrow;
    }
  }

  /// تسجيل الدخول
  Future<UserEntity?> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final hashedPassword = _hashPassword(password);
      final input = emailOrUsername.trim().toLowerCase();

      // البحث بالبريد الإلكتروني أو اسم المستخدم
      QuerySnapshot snapshot;
      
      // محاولة البحث بالبريد الإلكتروني
      snapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('email', isEqualTo: input)
          .where('password', isEqualTo: hashedPassword)
          .get();

      // إذا لم يجد، محاولة البحث باسم المستخدم
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection(AppConstants.collectionUsers)
            .where('username', isEqualTo: emailOrUsername.trim())
            .where('password', isEqualTo: hashedPassword)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      // التحقق من أن الحساب نشط
      if (data['isActive'] == false) {
        throw Exception('هذا الحساب معطل');
      }

      // تحديث آخر تسجيل دخول
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(doc.id)
          .update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      // حفظ بيانات الجلسة
      await _saveSession(doc.id);

      return UserEntity.fromFirestore(data, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login user error: $e');
      }
      rethrow;
    }
  }

  /// تسجيل الخروج
  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserType);
      await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout error: $e');
      }
    }
  }

  /// حفظ بيانات الجلسة
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyUserType, AppConstants.userTypeAuthenticated);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  /// استعادة الجلسة
  Future<UserEntity?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.keyUserId);
      final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

      if (!isLoggedIn || userId == null) {
        return null;
      }

      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!doc.exists) {
        await logoutUser();
        return null;
      }

      return UserEntity.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Restore session error: $e');
      }
      return null;
    }
  }

  /// الحصول على بيانات المستخدم
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserEntity.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get user by ID error: $e');
      }
      return null;
    }
  }

  /// تحديث بيانات المستخدم
  Future<bool> updateUser(UserEntity user) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.userId)
          .update({
        'username': user.username,
        'phone': user.phone,
        'profilePictureUrl': user.profilePictureUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update user error: $e');
      }
      return false;
    }
  }

  /// تغيير كلمة المرور
  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('المستخدم غير موجود');
      }

      final data = doc.data()!;
      final hashedOldPassword = _hashPassword(oldPassword);

      if (data['password'] != hashedOldPassword) {
        throw Exception('كلمة المرور الحالية غير صحيحة');
      }

      final hashedNewPassword = _hashPassword(newPassword);

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .update({
        'password': hashedNewPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Change password error: $e');
      }
      rethrow;
    }
  }

  /// البحث عن مستخدمين
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      final queryLower = query.toLowerCase().trim();
      
      // البحث بالبريد الإلكتروني
      final emailSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      // البحث باسم المستخدم
      final usernameSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('username', isGreaterThanOrEqualTo: query.trim())
          .where('username', isLessThan: '${query.trim()}z')
          .limit(10)
          .get();

      final Map<String, UserEntity> usersMap = {};

      for (final doc in emailSnapshot.docs) {
        usersMap[doc.id] = UserEntity.fromFirestore(doc.data(), doc.id);
      }

      for (final doc in usernameSnapshot.docs) {
        usersMap[doc.id] = UserEntity.fromFirestore(doc.data(), doc.id);
      }

      return usersMap.values.toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Search users error: $e');
      }
      return [];
    }
  }
}
