import '/domain/entities/entities.dart';

/// واجهة مستودع الحسابات
abstract class AccountRepository {
  /// الحصول على جميع الحسابات
  Future<List<AccountEntity>> getAllAccounts();
  
  /// الحصول على حساب بواسطة ID
  Future<AccountEntity?> getAccountById(String id);
  
  /// الحصول على حسابات مستخدم معين
  Future<List<AccountEntity>> getAccountsByUserId(String userId);
  
  /// الحصول على الحسابات حسب النوع
  Future<List<AccountEntity>> getAccountsByType(String userId, String type);
  
  /// إدراج حساب جديد
  Future<bool> insertAccount(AccountEntity account);
  
  /// تحديث حساب
  Future<bool> updateAccount(AccountEntity account);
  
  /// حذف حساب
  Future<bool> deleteAccount(String id);
  
  /// حذف جميع حسابات مستخدم
  Future<int> deleteAllUserAccounts(String userId);
  
  /// الحصول على إجمالي رصيد المستخدم
  Future<double> getTotalBalance(String userId);
}
