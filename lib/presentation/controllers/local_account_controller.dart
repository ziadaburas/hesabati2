import 'package:get/get.dart';
import '/data/services/database_service.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/auth_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// وحدة التحكم في الحسابات المحلية
class LocalAccountController extends GetxController {
  // Properties
  final localAccounts = <AccountEntity>[].obs;
  final totalBalance = 0.0.obs;
  final totalDebt = 0.0.obs;
  final totalLoan = 0.0.obs;
  final totalSavings = 0.0.obs;
  final isLoading = false.obs;
  final selectedAccount = Rxn<AccountEntity>();
  final errorMessage = ''.obs;

  // Services
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void onInit() {
    super.onInit();
    // لا نحمّل الحسابات هنا لأن المستخدم قد لا يكون موجوداً بعد
    // سيتم تحميل الحسابات عند الحاجة من الشاشات
    _initializeAfterAuth();
  }
  
  /// تهيئة بعد التحقق من حالة المصادقة
  Future<void> _initializeAfterAuth() async {
    try {
      // انتظر قليلاً للتأكد من تهيئة AuthController
      await Future.delayed(const Duration(milliseconds: 500));
      final authController = Get.find<AuthController>();
      if (authController.isLoggedIn.value) {
        await fetchLocalAccounts();
      }
    } catch (e) {
      // AuthController قد لا يكون جاهزاً بعد
    }
  }

  /// جلب جميع الحسابات المحلية
  Future<void> fetchLocalAccounts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;

      final results = await _databaseService.query(
        'accounts',
        where: 'user_id = ? AND account_category = ?',
        whereArgs: [userId, AppConstants.accountCategoryLocal],
        orderBy: 'created_at DESC',
      );

      localAccounts.value = results.map((map) => AccountEntity.fromMap(map)).toList();
      
      await calculateTotalBalance();
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء جلب الحسابات: $e';
      if (kDebugMode) {
        debugPrint('Fetch local accounts error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// حساب إجمالي الأرصدة
  Future<void> calculateTotalBalance() async {
    double total = 0.0;
    double debt = 0.0;
    double loan = 0.0;
    double savings = 0.0;

    for (final account in localAccounts) {
      total += account.balance;
      
      switch (account.accountType) {
        case AppConstants.accountTypeDebt:
          debt += account.balance;
          break;
        case AppConstants.accountTypeLoan:
          loan += account.balance;
          break;
        case AppConstants.accountTypeSavings:
          savings += account.balance;
          break;
      }
    }

    totalBalance.value = total;
    totalDebt.value = debt;
    totalLoan.value = loan;
    totalSavings.value = savings;
  }

  /// إنشاء حساب جديد
  Future<bool> createAccount(AccountEntity account) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _databaseService.insert('accounts', account.toMap());
      
      // تحديث القائمة
      await fetchLocalAccounts();
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إنشاء الحساب: $e';
      if (kDebugMode) {
        debugPrint('Create account error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث حساب
  Future<bool> updateAccount(AccountEntity account) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _databaseService.update(
        'accounts',
        account.toMap(),
        where: 'account_id = ?',
        whereArgs: [account.accountId],
      );
      
      // تحديث القائمة
      await fetchLocalAccounts();
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تحديث الحساب: $e';
      if (kDebugMode) {
        debugPrint('Update account error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف حساب
  Future<bool> deleteAccount(String accountId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // حذف العمليات المرتبطة أولاً
      await _databaseService.delete(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // حذف الحساب
      await _databaseService.delete(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
      
      // تحديث القائمة
      await fetchLocalAccounts();
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء حذف الحساب: $e';
      if (kDebugMode) {
        debugPrint('Delete account error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// الحصول على عمليات حساب معين
  Future<List<TransactionEntity>> getAccountTransactions(String accountId) async {
    try {
      final results = await _databaseService.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'transaction_date DESC',
      );

      return results.map((map) => TransactionEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get account transactions error: $e');
      }
      return [];
    }
  }

  /// الحصول على حساب بواسطة ID
  Future<AccountEntity?> getAccountById(String accountId) async {
    try {
      final results = await _databaseService.query(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      if (results.isNotEmpty) {
        return AccountEntity.fromMap(results.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get account by ID error: $e');
      }
      return null;
    }
  }

  /// تحديث رصيد الحساب بناءً على العمليات
  Future<void> updateAccountBalance(String accountId) async {
    try {
      // حساب إجمالي الوارد
      final inResults = await _databaseService.query(
        'transactions',
        where: 'account_id = ? AND transaction_type = ?',
        whereArgs: [accountId, AppConstants.transactionTypeIn],
      );
      
      double totalIn = 0.0;
      for (final r in inResults) {
        totalIn += (r['amount'] as num).toDouble();
      }

      // حساب إجمالي الصادر
      final outResults = await _databaseService.query(
        'transactions',
        where: 'account_id = ? AND transaction_type = ?',
        whereArgs: [accountId, AppConstants.transactionTypeOut],
      );
      
      double totalOut = 0.0;
      for (final r in outResults) {
        totalOut += (r['amount'] as num).toDouble();
      }

      // حساب الرصيد الجديد
      final newBalance = totalIn - totalOut;

      // تحديث الرصيد
      await _databaseService.update(
        'accounts',
        {
          'balance': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'account_id = ?',
        whereArgs: [accountId],
      );

      // تحديث القائمة
      await fetchLocalAccounts();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update account balance error: $e');
      }
    }
  }

  /// إنشاء حساب جديد بالقيم المحددة
  AccountEntity createNewAccount({
    required String accountName,
    required String accountType,
    String? otherPartyName,
    double initialBalance = 0.0,
  }) {
    final authController = Get.find<AuthController>();
    final now = DateTime.now();
    
    return AccountEntity(
      accountId: const Uuid().v4(),
      userId: authController.currentUserId,
      accountName: accountName,
      accountType: accountType,
      accountCategory: AppConstants.accountCategoryLocal,
      balance: initialBalance,
      currency: AppConstants.defaultCurrency,
      otherPartyName: otherPartyName,
      accountStatus: AppConstants.accountStatusActive,
      createdBy: authController.currentUserId,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      syncStatus: AppConstants.syncStatusOffline,
    );
  }

  /// الحصول على الحسابات حسب النوع
  List<AccountEntity> getAccountsByType(String type) {
    return localAccounts.where((a) => a.accountType == type).toList();
  }

  /// الحصول على عدد الحسابات
  int get accountsCount => localAccounts.length;

  /// مسح رسالة الخطأ
  void clearError() {
    errorMessage.value = '';
  }
}
