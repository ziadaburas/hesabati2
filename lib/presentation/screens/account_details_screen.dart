import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/transaction_form_screen.dart';
import '/presentation/screens/account_form_screen.dart';

/// شاشة تفاصيل الحساب
class AccountDetailsScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final LocalAccountController _accountController = Get.find<LocalAccountController>();
  final TransactionController _transactionController = Get.put(TransactionController());
  
  AccountEntity? _account;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    setState(() => _isLoading = true);
    
    _account = await _accountController.getAccountById(widget.accountId);
    await _transactionController.fetchTransactions(widget.accountId);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحساب')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحساب')),
        body: const Center(child: Text('الحساب غير موجود')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_account!.accountName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editAccount(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteAccount();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('حذف الحساب', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAccountDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountHeader(),
              _buildStatisticsSection(),
              const SizedBox(height: 16),
              _buildTransactionsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('عملية جديدة'),
      ),
    );
  }

  Widget _buildAccountHeader() {
    final Color typeColor = _getAccountTypeColor(_account!.accountType);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor, typeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // نوع الحساب
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _account!.accountTypeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // الرصيد
          Text(
            '${_account!.balance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // الطرف الآخر
          if (_account!.otherPartyName != null && _account!.otherPartyName!.isNotEmpty)
            Text(
              'الطرف الآخر: ${_account!.otherPartyName}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // حالة الحساب
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _account!.accountStatus == AppConstants.accountStatusActive
                    ? Icons.check_circle
                    : Icons.pending,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _account!.accountStatusLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Obx(() {
      final transactions = _transactionController.transactions;
      
      double totalIn = 0.0;
      double totalOut = 0.0;
      
      for (final t in transactions) {
        if (t.isIncoming) {
          totalIn += t.amount;
        } else {
          totalOut += t.amount;
        }
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.arrow_downward,
                title: 'إجمالي الوارد',
                value: '${totalIn.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.arrow_upward,
                title: 'إجمالي الصادر',
                value: '${totalOut.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'العمليات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(() => Text(
                '${_transactionController.transactions.length} عملية',
                style: TextStyle(color: Colors.grey[600]),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final transactions = _transactionController.transactions;
            
            if (transactions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد عمليات',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(transactions[index]);
              },
            );
          }),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionEntity transaction) {
    final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
    final isIncoming = transaction.isIncoming;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIncoming ? AppColors.success : AppColors.error).withOpacity(0.1),
          child: Icon(
            isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncoming ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          transaction.description.isEmpty ? transaction.transactionTypeLabel : transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dateFormat.format(transaction.transactionDate),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Text(
          '${isIncoming ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncoming ? AppColors.success : AppColors.error,
          ),
        ),
        onTap: () => _editTransaction(transaction),
      ),
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return AppColors.loan;
      case AppConstants.accountTypeDebt:
        return AppColors.debt;
      case AppConstants.accountTypeSavings:
        return AppColors.savings;
      case AppConstants.accountTypeShared:
        return AppColors.shared;
      default:
        return AppColors.primary;
    }
  }

  void _addTransaction() async {
    final result = await Get.to(() => TransactionFormScreen(accountId: widget.accountId));
    if (result == true) {
      await _loadAccountDetails();
    }
  }

  void _editTransaction(TransactionEntity transaction) async {
    final result = await Get.to(() => TransactionFormScreen(
      accountId: widget.accountId,
      transaction: transaction,
    ));
    if (result == true) {
      await _loadAccountDetails();
    }
  }

  void _editAccount() async {
    final result = await Get.to(() => AccountFormScreen(account: _account!.toMap()));
    if (result == true) {
      await _loadAccountDetails();
    }
  }

  void _confirmDeleteAccount() {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب؟ سيتم حذف جميع العمليات المرتبطة به.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await _accountController.deleteAccount(widget.accountId);
              if (success) {
                Get.back(result: true);
                Get.snackbar(
                  'نجح',
                  'تم حذف الحساب بنجاح',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'خطأ',
                  'حدث خطأ أثناء حذف الحساب',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
