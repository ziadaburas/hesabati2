import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/controllers.dart';
import '/data/services/connectivity_service.dart';
import '/data/services/sync_service.dart';
import '/presentation/screens/accounts_list_screen.dart';
import '/presentation/screens/shared_accounts_screen.dart';
import '/presentation/screens/notifications_screen.dart';
import '/presentation/screens/settings_screen.dart';
import '/presentation/screens/account_form_screen.dart';
import '/presentation/screens/account_details_screen.dart';

/// شاشة لوحة التحكم (الوضع المتصل)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final LocalAccountController _accountController = Get.find<LocalAccountController>();
  late final ConnectivityService _connectivityService;
  late final SyncService _syncService;
  
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _connectivityService = Get.find<ConnectivityService>();
    _syncService = Get.find<SyncService>();
    _accountController.fetchLocalAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appNameAr),
        actions: [
          // مؤشر الاتصال
          Obx(() => IconButton(
            icon: Icon(
              _connectivityService.isConnected.value
                  ? Icons.wifi
                  : Icons.wifi_off,
              color: _connectivityService.isConnected.value
                  ? AppColors.success
                  : AppColors.error,
            ),
            onPressed: () => _showConnectionStatus(),
          )),
          // زر المزامنة
          Obx(() => IconButton(
            icon: _syncService.isSyncing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Badge(
                    isLabelVisible: _syncService.pendingCount.value > 0,
                    label: Text('${_syncService.pendingCount.value}'),
                    child: const Icon(Icons.sync),
                  ),
            onPressed: _syncService.isSyncing.value ? null : () => _startSync(),
          )),
          // الإشعارات
          IconButton(
            icon: const Badge(
              isLabelVisible: false,
              child: Icon(Icons.notifications),
            ),
            onPressed: () => Get.to(() => const NotificationsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _accountController.fetchLocalAccounts();
          if (_connectivityService.isConnected.value) {
            await _syncService.syncAllData();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات المستخدم
              _buildUserHeader(),
              
              // الإحصائيات
              _buildStatisticsSection(),
              
              // التبويبات
              _buildTabsSection(),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAccount(),
        icon: const Icon(Icons.add),
        label: const Text('حساب جديد'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'حساباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'مشتركة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Obx(() {
      final user = _authController.currentUser.value;
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: user?.profilePictureUrl != null
                  ? NetworkImage(user!.profilePictureUrl!)
                  : null,
              child: user?.profilePictureUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، ${user?.username ?? 'مستخدم'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _connectivityService.isConnected.value
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connectivityService.isConnected.value
                            ? 'متصل بالسحابة'
                            : 'غير متصل',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatisticsSection() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    title: 'عدد الحسابات',
                    value: '${_accountController.accountsCount}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    title: 'إجمالي الأرصدة',
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
                    icon: Icons.arrow_circle_up,
                    title: 'المديونية',
                    value: '${_accountController.totalDebt.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                    color: AppColors.debt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.arrow_circle_down,
                    title: 'الديون',
                    value: '${_accountController.totalLoan.value.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                    color: AppColors.loan,
                  ),
                ),
              ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildTabsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر الحسابات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final accounts = _accountController.localAccounts.take(5).toList();
            
            if (accounts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد حسابات',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: accounts.map((account) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAccountTypeColor(account.accountType).withOpacity(0.1),
                      child: Icon(
                        _getAccountTypeIcon(account.accountType),
                        color: _getAccountTypeColor(account.accountType),
                      ),
                    ),
                    title: Text(account.accountName),
                    subtitle: Text(account.accountTypeLabel),
                    trailing: Text(
                      '${account.balance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Get.to(() => AccountDetailsScreen(accountId: account.accountId)),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Get.to(() => const AccountsListScreen()),
            child: const Text('عرض جميع الحسابات'),
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

  void _onTabSelected(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Get.to(() => const AccountsListScreen());
        break;
      case 2:
        Get.to(() => const SharedAccountsScreen());
        break;
      case 3:
        Get.to(() => const SettingsScreen());
        break;
    }
  }

  void _showConnectionStatus() {
    Get.snackbar(
      'حالة الاتصال',
      _connectivityService.isConnected.value
          ? 'متصل عبر ${_connectivityService.connectionTypeLabel}'
          : 'غير متصل بالإنترنت',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _connectivityService.isConnected.value
          ? AppColors.success
          : AppColors.error,
      colorText: Colors.white,
    );
  }

  void _startSync() async {
    if (!_connectivityService.isConnected.value) {
      Get.snackbar(
        'خطأ',
        'لا يوجد اتصال بالإنترنت',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final success = await _syncService.syncAllData();
    
    Get.snackbar(
      success ? 'نجح' : 'خطأ',
      success ? 'تمت المزامنة بنجاح' : 'حدث خطأ أثناء المزامنة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success ? AppColors.success : AppColors.error,
      colorText: Colors.white,
    );
  }

  void _addAccount() async {
    final result = await Get.to(() => const AccountFormScreen());
    if (result == true) {
      await _accountController.fetchLocalAccounts();
    }
  }
}
