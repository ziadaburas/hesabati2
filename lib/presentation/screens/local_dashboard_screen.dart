import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/account_form_screen.dart';
import '/presentation/screens/account_details_screen.dart';
import '/presentation/screens/accounts_list_screen.dart';
import '/presentation/screens/settings_screen.dart';
import '/presentation/screens/reports_screen.dart';

class LocalDashboardScreen extends StatefulWidget {
  const LocalDashboardScreen({super.key});

  @override
  State<LocalDashboardScreen> createState() => _LocalDashboardScreenState();
}

class _LocalDashboardScreenState extends State<LocalDashboardScreen> {
  int _selectedIndex = 0;
  final LocalAccountController _accountController = Get.find<LocalAccountController>();

  @override
  void initState() {
    super.initState();
    _accountController.fetchLocalAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('local_accounts'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Get.to(() => const ReportsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _accountController.fetchLocalAccounts(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),
                  
                  // Accounts List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'accounts'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => const AccountsListScreen()),
                        child: Text('all'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Accounts List
                  _buildAccountsList(),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const AccountFormScreen());
          if (result == true) {
            await _accountController.fetchLocalAccounts();
          }
        },
        icon: const Icon(Icons.add),
        label: Text('new_account'.tr),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Get.to(() => const AccountsListScreen());
              break;
            case 2:
              Get.to(() => const SettingsScreen());
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: 'accounts'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'settings'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Obx(() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'accounts'.tr,
                  value: '${_accountController.accountsCount}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'total_balance'.tr,
                  value: '${_accountController.totalBalance.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.arrow_circle_down,
                  title: 'loan'.tr,
                  value: '${_accountController.totalLoan.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                  color: AppColors.loan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.arrow_circle_up,
                  title: 'debt'.tr,
                  value: '${_accountController.totalDebt.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                  color: AppColors.debt,
                ),
              ),
            ],
          ),
        ],
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
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

  Widget _buildAccountsList() {
    return Obx(() {
      if (_accountController.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final accounts = _accountController.localAccounts;

      if (accounts.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'no_accounts'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'add_first_account'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accounts.length > 5 ? 5 : accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          final typeColor = _getAccountTypeColor(account.accountType);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: typeColor.withOpacity(0.1),
                child: Icon(
                  _getAccountTypeIcon(account.accountType),
                  color: typeColor,
                ),
              ),
              title: Text(account.accountName),
              subtitle: Text(_getAccountTypeLabel(account.accountType)),
              trailing: Text(
                '${account.balance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: typeColor,
                ),
              ),
              onTap: () async {
                final result = await Get.to(() => AccountDetailsScreen(accountId: account.accountId));
                if (result == true) {
                  await _accountController.fetchLocalAccounts();
                }
              },
            ),
          );
        },
      );
    });
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

  String _getAccountTypeLabel(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return 'loan'.tr;
      case AppConstants.accountTypeDebt:
        return 'debt'.tr;
      case AppConstants.accountTypeSavings:
        return 'savings'.tr;
      case AppConstants.accountTypeShared:
        return 'shared'.tr;
      default:
        return type;
    }
  }
}
