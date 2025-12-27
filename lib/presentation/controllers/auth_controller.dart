import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/data/services/firestore_auth_service.dart';
import '/data/services/database_service.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// وحدة التحكم في المصادقة
class AuthController extends GetxController {
  // Properties
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserEntity>();
  final errorMessage = ''.obs;
  final userType = AppConstants.userTypeLocal.obs;
  final lastSyncTime = ''.obs;

  // Services
  final FirestoreAuthService _authService = FirestoreAuthService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void onInit() {
    super.onInit();
    _initAuthState();
  }

  /// تهيئة حالة المصادقة
  Future<void> _initAuthState() async {
    await restoreSession();
  }

  /// استعادة الجلسة المحفوظة
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(AppConstants.keyUserId);
      final savedUserType = prefs.getString(AppConstants.keyUserType);
      final savedIsLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      final savedLastSync = prefs.getString(AppConstants.keyLastSyncTime);

      if (savedLastSync != null) {
        lastSyncTime.value = savedLastSync;
      }

      if (savedIsLoggedIn && savedUserId != null) {
        userType.value = savedUserType ?? AppConstants.userTypeLocal;
        
        if (userType.value == AppConstants.userTypeAuthenticated) {
          // تحميل بيانات المستخدم من Firestore
          final user = await _authService.restoreSession();
          if (user != null) {
            currentUser.value = user;
            isLoggedIn.value = true;
          } else {
            // الجلسة غير صالحة
            await signOut();
          }
        } else {
          // تحميل بيانات المستخدم المحلي
          await _loadLocalUser(savedUserId);
          isLoggedIn.value = true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Restore session error: $e');
      }
    }
  }

  /// تحميل بيانات المستخدم المحلي
  Future<void> _loadLocalUser(String userId) async {
    try {
      final results = await _databaseService.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isNotEmpty) {
        currentUser.value = UserEntity.fromMap(results.first);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Load local user error: $e');
      }
    }
  }

  /// تسجيل مستخدم جديد
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authService.registerUser(
        username: username,
        email: email,
        password: password,
        phone: phone,
      );

      if (user != null) {
        currentUser.value = user;
        isLoggedIn.value = true;
        userType.value = AppConstants.userTypeAuthenticated;
        return true;
      }

      return false;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الدخول
  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authService.loginUser(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      if (user != null) {
        currentUser.value = user;
        isLoggedIn.value = true;
        userType.value = AppConstants.userTypeAuthenticated;
        return true;
      }

      return false;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء مستخدم محلي
  Future<bool> createLocalUser() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userId = const Uuid().v4();
      final now = DateTime.now();
      
      final localUser = UserEntity(
        userId: userId,
        username: 'مستخدم محلي',
        email: '',
        userType: AppConstants.userTypeLocal,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      // حفظ في قاعدة البيانات المحلية
      await _databaseService.insert('users', localUser.toMap());

      // حفظ الجلسة
      await _saveSession(userId, AppConstants.userTypeLocal);

      currentUser.value = localUser;
      isLoggedIn.value = true;
      userType.value = AppConstants.userTypeLocal;

      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إنشاء المستخدم المحلي: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ الجلسة
  Future<void> _saveSession(String userId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, userId);
      await prefs.setString(AppConstants.keyUserType, type);
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Save session error: $e');
      }
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      if (userType.value == AppConstants.userTypeAuthenticated) {
        await _authService.logoutUser();
      }

      // مسح الجلسة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserType);
      await prefs.setBool(AppConstants.keyIsLoggedIn, false);

      // إعادة تعيين الحالة
      currentUser.value = null;
      isLoggedIn.value = false;
      userType.value = AppConstants.userTypeLocal;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تسجيل الخروج: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات المستخدم
  Future<bool> updateUserProfile({
    required String username,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentUser.value == null) return false;

      final updatedUser = currentUser.value!.copyWith(
        username: username,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      if (userType.value == AppConstants.userTypeAuthenticated) {
        final success = await _authService.updateUser(updatedUser);
        if (!success) {
          throw Exception('فشل تحديث البيانات');
        }
      } else {
        // تحديث في قاعدة البيانات المحلية
        await _databaseService.update(
          'users',
          updatedUser.toMap(),
          where: 'user_id = ?',
          whereArgs: [updatedUser.userId],
        );
      }

      currentUser.value = updatedUser;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تغيير كلمة المرور
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentUser.value == null) return false;

      if (userType.value != AppConstants.userTypeAuthenticated) {
        throw Exception('هذه الميزة متاحة فقط للمستخدمين المسجلين');
      }

      await _authService.changePassword(
        userId: currentUser.value!.userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// مسح رسالة الخطأ
  void clearError() {
    errorMessage.value = '';
  }

  /// تحديث وقت آخر مزامنة
  Future<void> updateLastSyncTime() async {
    final now = DateTime.now().toIso8601String();
    lastSyncTime.value = now;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastSyncTime, now);
  }

  /// الحصول على User ID الحالي
  String get currentUserId => currentUser.value?.userId ?? 'local_user';

  /// هل المستخدم في الوضع المحلي؟
  bool get isLocalMode => userType.value == AppConstants.userTypeLocal;

  /// هل المستخدم في الوضع المتصل؟
  bool get isAuthenticatedMode => userType.value == AppConstants.userTypeAuthenticated;
}
