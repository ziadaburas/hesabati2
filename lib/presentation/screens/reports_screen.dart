import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة التقارير
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalAccountController _accountController = Get.find<LocalAccountController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ملخص'),
            Tab(text: 'تفاصيل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إجمالي الحسابات
          _buildSummaryCard(
            title: 'ملخص الحسابات',
            children: [
              Obx(() => _buildSummaryRow(
                'إجمالي الحسابات',
                '${_accountController.accountsCount}',
                AppColors.primary,
              )),
              const Divider(),
              Obx(() => _buildSummaryRow(
                'إجمالي الأرصدة',
                '${_accountController.totalBalance.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                AppColors.success,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // توزيع الحسابات حسب النوع
          _buildSummaryCard(
            title: 'توزيع الحسابات',
            children: [
              Obx(() {
                final loanAccounts = _accountController
                    .getAccountsByType(AppConstants.accountTypeLoan);
                return _buildSummaryRow(
                  'حسابات الديون',
                  '${loanAccounts.length}',
                  AppColors.loan,
                  icon: Icons.arrow_circle_down,
                );
              }),
              const Divider(),
              Obx(() {
                final debtAccounts = _accountController
                    .getAccountsByType(AppConstants.accountTypeDebt);
                return _buildSummaryRow(
                  'حسابات المديونية',
                  '${debtAccounts.length}',
                  AppColors.debt,
                  icon: Icons.arrow_circle_up,
                );
              }),
              const Divider(),
              Obx(() {
                final savingsAccounts = _accountController
                    .getAccountsByType(AppConstants.accountTypeSavings);
                return _buildSummaryRow(
                  'حسابات التوفير',
                  '${savingsAccounts.length}',
                  AppColors.savings,
                  icon: Icons.savings,
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // توزيع الأرصدة
          _buildSummaryCard(
            title: 'توزيع الأرصدة',
            children: [
              Obx(() => _buildSummaryRow(
                'الديون (لك)',
                '${_accountController.totalLoan.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                AppColors.loan,
              )),
              const Divider(),
              Obx(() => _buildSummaryRow(
                'المديونية (عليك)',
                '${_accountController.totalDebt.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                AppColors.debt,
              )),
              const Divider(),
              Obx(() => _buildSummaryRow(
                'التوفير',
                '${_accountController.totalSavings.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                AppColors.savings,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // صافي الوضع المالي
          Obx(() {
            final netBalance = _accountController.totalLoan.value -
                _accountController.totalDebt.value;
            final isPositive = netBalance >= 0;
            
            return Card(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'صافي الوضع المالي',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${netBalance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPositive
                          ? 'وضعك المالي جيد 👍'
                          : 'عليك مديونية أكثر من ديونك',
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Obx(() {
      final accounts = _accountController.localAccounts;
      
      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'لا توجد بيانات للعرض',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          final typeColor = _getAccountTypeColor(account.accountType);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getAccountTypeIcon(account.accountType),
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.accountName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              account.accountTypeLabel,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${account.balance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                  if (account.otherPartyName != null &&
                      account.otherPartyName!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            account.otherPartyName!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
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
      default:
        return AppColors.primary;
    }
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return Icons.arrow_circle_down;
      case AppConstants.accountTypeDebt:
        return Icons.arrow_circle_up;
      case AppConstants.accountTypeSavings:
        return Icons.savings;
      default:
        return Icons.account_balance;
    }
  }
}
