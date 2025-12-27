import 'dart:async';
import 'package:get/get.dart';
import '/data/services/database_service.dart';
import '/data/services/firebase_service.dart';
import '/data/services/connectivity_service.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';

/// خدمة المزامنة
class SyncService extends GetxService {
  static SyncService get instance => Get.find<SyncService>();
  
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Properties
  final isSyncing = false.obs;
  final lastSyncTime = ''.obs;
  final pendingCount = 0.obs;
  final syncStatus = 'idle'.obs; // idle, syncing, error, success
  final syncProgress = 0.0.obs;
  final errorMessage = ''.obs;

  /// بدء عملية المزامنة الكاملة
  Future<bool> syncAllData() async {
    final connectivityService = Get.find<ConnectivityService>();
    
    if (!connectivityService.isConnected.value) {
      errorMessage.value = 'لا يوجد اتصال بالإنترنت';
      syncStatus.value = 'error';
      return false;
    }

    if (isSyncing.value) {
      return false;
    }

    try {
      isSyncing.value = true;
      syncStatus.value = 'syncing';
      syncProgress.value = 0.0;
      errorMessage.value = '';

      // مزامنة الحسابات
      syncProgress.value = 0.2;
      await syncAccounts();

      // مزامنة العمليات
      syncProgress.value = 0.5;
      await syncTransactions();

      // مزامنة الطلبات
      syncProgress.value = 0.8;
      await syncRequests();

      // تحديث وقت آخر مزامنة
      syncProgress.value = 1.0;
      lastSyncTime.value = DateTime.now().toIso8601String();
      
      final authController = Get.find<AuthController>();
      await authController.updateLastSyncTime();

      syncStatus.value = 'success';
      await _updatePendingCount();
      
      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء المزامنة: $e';
      syncStatus.value = 'error';
      if (kDebugMode) {
        debugPrint('Sync all data error: $e');
      }
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// مزامنة الحسابات
  Future<bool> syncAccounts() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;

      // رفع الحسابات المحلية غير المزامنة
      final unsyncedAccounts = await _databaseService.query(
        'accounts',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
      );

      for (final accountMap in unsyncedAccounts) {
        final account = AccountEntity.fromMap(accountMap);
        final remoteId = await _firebaseService.createAccount(account);
        
        if (remoteId != null) {
          await _databaseService.update(
            'accounts',
            {
              'is_synced': 1,
              'sync_status': AppConstants.syncStatusSynced,
            },
            where: 'account_id = ?',
            whereArgs: [account.accountId],
          );
        }
      }

      // تحميل الحسابات من Firebase
      final remoteAccounts = await _firebaseService.getUserAccounts(userId);
      
      for (final remoteAccount in remoteAccounts) {
        // التحقق من وجود الحساب محلياً
        final localResults = await _databaseService.query(
          'accounts',
          where: 'account_id = ?',
          whereArgs: [remoteAccount.accountId],
        );

        if (localResults.isEmpty) {
          // إضافة الحساب محلياً
          await _databaseService.insert('accounts', remoteAccount.toMap());
        } else {
          // تحديث الحساب المحلي
          final localAccount = AccountEntity.fromMap(localResults.first);
          if (remoteAccount.updatedAt.isAfter(localAccount.updatedAt)) {
            await _databaseService.update(
              'accounts',
              remoteAccount.toMap(),
              where: 'account_id = ?',
              whereArgs: [remoteAccount.accountId],
            );
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync accounts error: $e');
      }
      return false;
    }
  }

  /// مزامنة العمليات
  Future<bool> syncTransactions() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;

      // الحصول على حسابات المستخدم
      final accounts = await _databaseService.query(
        'accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final accountMap in accounts) {
        final accountId = accountMap['account_id'] as String;

        // رفع العمليات غير المزامنة
        final unsyncedTransactions = await _databaseService.query(
          'transactions',
          where: 'account_id = ? AND is_synced = 0',
          whereArgs: [accountId],
        );

        for (final transactionMap in unsyncedTransactions) {
          final transaction = TransactionEntity.fromMap(transactionMap);
          final remoteId = await _firebaseService.createTransaction(transaction);
          
          if (remoteId != null) {
            await _databaseService.update(
              'transactions',
              {
                'is_synced': 1,
                'transaction_status': AppConstants.syncStatusSynced,
              },
              where: 'transaction_id = ?',
              whereArgs: [transaction.transactionId],
            );
          }
        }

        // تحميل العمليات من Firebase
        final remoteTransactions = await _firebaseService.getAccountTransactions(accountId);
        
        for (final remoteTransaction in remoteTransactions) {
          final localResults = await _databaseService.query(
            'transactions',
            where: 'transaction_id = ?',
            whereArgs: [remoteTransaction.transactionId],
          );

          if (localResults.isEmpty) {
            await _databaseService.insert('transactions', remoteTransaction.toMap());
          } else {
            final localTransaction = TransactionEntity.fromMap(localResults.first);
            if (remoteTransaction.updatedAt.isAfter(localTransaction.updatedAt)) {
              await _databaseService.update(
                'transactions',
                remoteTransaction.toMap(),
                where: 'transaction_id = ?',
                whereArgs: [remoteTransaction.transactionId],
              );
            }
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync transactions error: $e');
      }
      return false;
    }
  }

  /// مزامنة الطلبات
  Future<bool> syncRequests() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;

      // رفع الطلبات غير المزامنة
      final unsyncedRequests = await _databaseService.query(
        'account_requests',
        where: '(from_user_id = ? OR to_user_id = ?) AND is_synced = 0',
        whereArgs: [userId, userId],
      );

      for (final requestMap in unsyncedRequests) {
        final request = AccountRequestEntity.fromMap(requestMap);
        final remoteId = await _firebaseService.createAccountRequest(request);
        
        if (remoteId != null) {
          await _databaseService.update(
            'account_requests',
            {'is_synced': 1},
            where: 'request_id = ?',
            whereArgs: [request.requestId],
          );
        }
      }

      // تحميل الطلبات الواردة من Firebase
      final incomingRequests = await _firebaseService.getIncomingRequests(userId);
      
      for (final request in incomingRequests) {
        final localResults = await _databaseService.query(
          'account_requests',
          where: 'request_id = ?',
          whereArgs: [request.requestId],
        );

        if (localResults.isEmpty) {
          await _databaseService.insert('account_requests', request.toMap());
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync requests error: $e');
      }
      return false;
    }
  }

  /// تحديث عدد البيانات المعلقة
  Future<void> _updatePendingCount() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;

      // عدد الحسابات غير المزامنة
      final unsyncedAccounts = await _databaseService.query(
        'accounts',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
      );

      // عدد العمليات غير المزامنة
      final unsyncedTransactions = await _databaseService.query(
        'transactions',
        where: 'is_synced = 0',
      );

      pendingCount.value = unsyncedAccounts.length + unsyncedTransactions.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update pending count error: $e');
      }
    }
  }

  /// إعادة محاولة المزامنة الفاشلة
  Future<void> retryFailedSync() async {
    await syncAllData();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    errorMessage.value = '';
    if (syncStatus.value == 'error') {
      syncStatus.value = 'idle';
    }
  }

  /// Stream لمتابعة تقدم المزامنة
  Stream<double> onSyncProgress() {
    return syncProgress.stream;
  }
}
