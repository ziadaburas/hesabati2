import 'package:get/get.dart';
import '/data/services/database_service.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/auth_controller.dart';
import '/presentation/controllers/local_account_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// وحدة التحكم في العمليات
class TransactionController extends GetxController {
  // Properties
  final transactions = <TransactionEntity>[].obs;
  final isLoading = false.obs;
  final selectedTransaction = Rxn<TransactionEntity>();
  final errorMessage = ''.obs;
  final currentAccountId = ''.obs;

  // Services
  final DatabaseService _databaseService = DatabaseService.instance;

  /// جلب عمليات حساب معين
  Future<void> fetchTransactions(String accountId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentAccountId.value = accountId;

      final results = await _databaseService.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'transaction_date DESC',
      );

      transactions.value = results.map((map) => TransactionEntity.fromMap(map)).toList();
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء جلب العمليات: $e';
      if (kDebugMode) {
        debugPrint('Fetch transactions error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء عملية جديدة
  Future<bool> createTransaction(TransactionEntity transaction) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _databaseService.insert('transactions', transaction.toMap());
      
      // تحديث رصيد الحساب
      final accountController = Get.find<LocalAccountController>();
      await accountController.updateAccountBalance(transaction.accountId);
      
      // تحديث القائمة
      if (currentAccountId.value == transaction.accountId) {
        await fetchTransactions(transaction.accountId);
      }
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إنشاء العملية: $e';
      if (kDebugMode) {
        debugPrint('Create transaction error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث عملية
  Future<bool> updateTransaction(TransactionEntity transaction) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _databaseService.update(
        'transactions',
        transaction.toMap(),
        where: 'transaction_id = ?',
        whereArgs: [transaction.transactionId],
      );
      
      // تحديث رصيد الحساب
      final accountController = Get.find<LocalAccountController>();
      await accountController.updateAccountBalance(transaction.accountId);
      
      // تحديث القائمة
      if (currentAccountId.value == transaction.accountId) {
        await fetchTransactions(transaction.accountId);
      }
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تحديث العملية: $e';
      if (kDebugMode) {
        debugPrint('Update transaction error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف عملية
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // الحصول على العملية لمعرفة الحساب
      final results = await _databaseService.query(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      if (results.isEmpty) {
        errorMessage.value = 'العملية غير موجودة';
        return false;
      }

      final accountId = results.first['account_id'] as String;

      // حذف العملية
      await _databaseService.delete(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
      
      // تحديث رصيد الحساب
      final accountController = Get.find<LocalAccountController>();
      await accountController.updateAccountBalance(accountId);
      
      // تحديث القائمة
      if (currentAccountId.value == accountId) {
        await fetchTransactions(accountId);
      }
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء حذف العملية: $e';
      if (kDebugMode) {
        debugPrint('Delete transaction error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// حساب رصيد الحساب من العمليات
  Future<double> calculateAccountBalance(String accountId) async {
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

      return totalIn - totalOut;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Calculate account balance error: $e');
      }
      return 0.0;
    }
  }

  /// إنشاء عملية جديدة بالقيم المحددة
  TransactionEntity createNewTransaction({
    required String accountId,
    required double amount,
    required String transactionType,
    required String description,
    String? notes,
    DateTime? transactionDate,
  }) {
    final authController = Get.find<AuthController>();
    final now = DateTime.now();
    
    return TransactionEntity(
      transactionId: const Uuid().v4(),
      accountId: accountId,
      amount: amount,
      transactionType: transactionType,
      description: description,
      notes: notes,
      transactionDate: transactionDate ?? now,
      recordedByUser: authController.currentUserId,
      status: AppConstants.transactionStatusCompleted,
      transactionStatus: AppConstants.syncStatusOffline,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  /// الحصول على إجمالي الوارد لحساب معين
  double getTotalIncoming(String accountId) {
    return transactions
        .where((t) => t.accountId == accountId && t.isIncoming)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// الحصول على إجمالي الصادر لحساب معين
  double getTotalOutgoing(String accountId) {
    return transactions
        .where((t) => t.accountId == accountId && t.isOutgoing)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// الحصول على عدد العمليات
  int get transactionsCount => transactions.length;

  /// مسح رسالة الخطأ
  void clearError() {
    errorMessage.value = '';
  }

  /// الحصول على آخر العمليات
  List<TransactionEntity> getRecentTransactions({int limit = 5}) {
    final sorted = List<TransactionEntity>.from(transactions);
    sorted.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted.take(limit).toList();
  }
}
