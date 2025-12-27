import '/domain/entities/entities.dart';
import '/domain/repositories/transaction_repository.dart';
import '/data/services/database_service.dart';
import '/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// تطبيق مستودع العمليات
class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseService _databaseService;

  TransactionRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    try {
      final results = await _databaseService.getAllFromTable('transactions');
      return results.map((map) => TransactionEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get all transactions error: $e');
      }
      return [];
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByAccountId(String accountId) async {
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
        debugPrint('Get transactions by account ID error: $e');
      }
      return [];
    }
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    try {
      final results = await _databaseService.query(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      
      if (results.isNotEmpty) {
        return TransactionEntity.fromMap(results.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get transaction by ID error: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> insertTransaction(TransactionEntity transaction) async {
    try {
      await _databaseService.insert('transactions', transaction.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Insert transaction error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> updateTransaction(TransactionEntity transaction) async {
    try {
      await _databaseService.update(
        'transactions',
        transaction.toMap(),
        where: 'transaction_id = ?',
        whereArgs: [transaction.transactionId],
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update transaction error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    try {
      await _databaseService.delete(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete transaction error: $e');
      }
      return false;
    }
  }

  @override
  Future<int> deleteAllAccountTransactions(String accountId) async {
    try {
      return await _databaseService.delete(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete all account transactions error: $e');
      }
      return 0;
    }
  }

  @override
  Future<double> getSumByAccountId(String accountId, String type) async {
    try {
      final results = await _databaseService.query(
        'transactions',
        where: 'account_id = ? AND transaction_type = ?',
        whereArgs: [accountId, type],
      );
      
      double sum = 0.0;
      for (final r in results) {
        sum += (r['amount'] as num).toDouble();
      }
      return sum;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get sum by account ID error: $e');
      }
      return 0.0;
    }
  }

  @override
  Future<List<TransactionEntity>> getRecentTransactions(String accountId, {int limit = 10}) async {
    try {
      final results = await _databaseService.query(
        'transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'transaction_date DESC',
        limit: limit,
      );
      return results.map((map) => TransactionEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get recent transactions error: $e');
      }
      return [];
    }
  }

  /// الحصول على رصيد الحساب من العمليات
  Future<double> calculateAccountBalance(String accountId) async {
    final totalIn = await getSumByAccountId(accountId, AppConstants.transactionTypeIn);
    final totalOut = await getSumByAccountId(accountId, AppConstants.transactionTypeOut);
    return totalIn - totalOut;
  }
}
