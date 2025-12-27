import '/domain/entities/entities.dart';
import '/domain/repositories/account_repository.dart';
import '/data/services/database_service.dart';
import 'package:flutter/foundation.dart';

/// تطبيق مستودع الحسابات
class AccountRepositoryImpl implements AccountRepository {
  final DatabaseService _databaseService;

  AccountRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  @override
  Future<List<AccountEntity>> getAllAccounts() async {
    try {
      final results = await _databaseService.getAllFromTable('accounts');
      return results.map((map) => AccountEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get all accounts error: $e');
      }
      return [];
    }
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    try {
      final results = await _databaseService.query(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [id],
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

  @override
  Future<List<AccountEntity>> getAccountsByUserId(String userId) async {
    try {
      final results = await _databaseService.query(
        'accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return results.map((map) => AccountEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get accounts by user ID error: $e');
      }
      return [];
    }
  }

  @override
  Future<List<AccountEntity>> getAccountsByType(String userId, String type) async {
    try {
      final results = await _databaseService.query(
        'accounts',
        where: 'user_id = ? AND account_type = ?',
        whereArgs: [userId, type],
        orderBy: 'created_at DESC',
      );
      return results.map((map) => AccountEntity.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get accounts by type error: $e');
      }
      return [];
    }
  }

  @override
  Future<bool> insertAccount(AccountEntity account) async {
    try {
      await _databaseService.insert('accounts', account.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Insert account error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> updateAccount(AccountEntity account) async {
    try {
      await _databaseService.update(
        'accounts',
        account.toMap(),
        where: 'account_id = ?',
        whereArgs: [account.accountId],
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update account error: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteAccount(String id) async {
    try {
      await _databaseService.delete(
        'accounts',
        where: 'account_id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete account error: $e');
      }
      return false;
    }
  }

  @override
  Future<int> deleteAllUserAccounts(String userId) async {
    try {
      return await _databaseService.delete(
        'accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete all user accounts error: $e');
      }
      return 0;
    }
  }

  @override
  Future<double> getTotalBalance(String userId) async {
    try {
      final results = await _databaseService.query(
        'accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      double total = 0.0;
      for (final r in results) {
        total += (r['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get total balance error: $e');
      }
      return 0.0;
    }
  }
}
