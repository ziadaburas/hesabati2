import '/domain/entities/entities.dart';

/// واجهة مستودع العمليات
abstract class TransactionRepository {
  /// الحصول على جميع العمليات
  Future<List<TransactionEntity>> getAllTransactions();
  
  /// الحصول على عمليات حساب معين
  Future<List<TransactionEntity>> getTransactionsByAccountId(String accountId);
  
  /// الحصول على عملية بواسطة ID
  Future<TransactionEntity?> getTransactionById(String id);
  
  /// إدراج عملية جديدة
  Future<bool> insertTransaction(TransactionEntity transaction);
  
  /// تحديث عملية
  Future<bool> updateTransaction(TransactionEntity transaction);
  
  /// حذف عملية
  Future<bool> deleteTransaction(String id);
  
  /// حذف جميع عمليات حساب
  Future<int> deleteAllAccountTransactions(String accountId);
  
  /// الحصول على مجموع العمليات حسب النوع
  Future<double> getSumByAccountId(String accountId, String type);
  
  /// الحصول على آخر العمليات
  Future<List<TransactionEntity>> getRecentTransactions(String accountId, {int limit = 10});
}
