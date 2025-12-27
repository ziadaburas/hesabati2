import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/create_shared_account_screen.dart';

/// شاشة الحسابات المشتركة
class SharedAccountsScreen extends StatefulWidget {
  const SharedAccountsScreen({super.key});

  @override
  State<SharedAccountsScreen> createState() => _SharedAccountsScreenState();
}

class _SharedAccountsScreenState extends State<SharedAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  List<AccountEntity> _sharedAccounts = [];
  List<AccountRequestEntity> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authController.currentUserId;
      
      if (userId.isEmpty || userId == 'local_user') {
        Get.snackbar(
          'تنبيه',
          'يجب تسجيل الدخول للوصول إلى الحسابات المشتركة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // تحميل الحسابات المشتركة
      final allAccounts = await _firebaseService.getUserAccounts(userId);
      _sharedAccounts = allAccounts
          .where((a) => a.accountCategory == AppConstants.accountCategoryShared)
          .toList();
      
      // تحميل الطلبات المعلقة
      _pendingRequests = await _firebaseService.getIncomingRequests(userId);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء تحميل البيانات: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحسابات المشتركة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'الكل'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('طلبات'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'نشطة'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllAccountsTab(),
                  _buildRequestsTab(),
                  _buildActiveAccountsTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSharedAccount,
        icon: const Icon(Icons.add),
        label: const Text('حساب مشترك'),
      ),
    );
  }

  Widget _buildAllAccountsTab() {
    if (_sharedAccounts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'لا توجد حسابات مشتركة',
        subtitle: 'ابدأ بإنشاء حساب مشترك مع مستخدم آخر',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sharedAccounts.length,
      itemBuilder: (context, index) {
        return _buildAccountCard(_sharedAccounts[index]);
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'لا توجد طلبات',
        subtitle: 'ستظهر هنا طلبات الحسابات المشتركة الواردة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(_pendingRequests[index]);
      },
    );
  }

  Widget _buildActiveAccountsTab() {
    final activeAccounts = _sharedAccounts
        .where((a) => a.accountStatus == AppConstants.accountStatusActive)
        .toList();

    if (activeAccounts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'لا توجد حسابات نشطة',
        subtitle: 'الحسابات المشتركة النشطة ستظهر هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeAccounts.length,
      itemBuilder: (context, index) {
        return _buildAccountCard(activeAccounts[index]);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountEntity account) {
    final Color statusColor = _getStatusColor(account.accountStatus);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.shared.withOpacity(0.1),
          child: const Icon(Icons.people, color: AppColors.shared),
        ),
        title: Text(
          account.accountName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    account.accountStatusLabel,
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ),
                if (account.otherPartyName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'مع: ${account.otherPartyName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${account.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              AppConstants.currencySymbol,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
          // فتح تفاصيل الحساب
        },
      ),
    );
  }

  Widget _buildRequestCard(AccountRequestEntity request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  child: const Icon(Icons.pending, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.accountName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طلب من: ${request.fromUserName ?? request.fromUserId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'نوع الحساب: ${_getAccountTypeLabel(request.accountType)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToRequest(request, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToRequest(request, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('قبول'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.accountStatusActive:
        return AppColors.success;
      case AppConstants.accountStatusPending:
        return AppColors.warning;
      case AppConstants.accountStatusClosed:
        return AppColors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _getAccountTypeLabel(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return 'دين';
      case AppConstants.accountTypeDebt:
        return 'مديونية';
      case AppConstants.accountTypeSavings:
        return 'توفير';
      default:
        return type;
    }
  }

  void _createSharedAccount() async {
    final result = await Get.to(() => const CreateSharedAccountScreen());
    if (result == true) {
      await _loadData();
    }
  }

  void _respondToRequest(AccountRequestEntity request, bool accept) async {
    // عرض مؤشر التحميل
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      final success = await _firebaseService.respondToAccountRequest(
        request.requestId,
        accept,
        null,
      );

      // إغلاق مؤشر التحميل
      Get.back();

      if (success) {
        Get.snackbar(
          'نجح',
          accept ? 'تم قبول الطلب وإنشاء الحساب المشترك' : 'تم رفض الطلب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        await _loadData();
      } else {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء الرد على الطلب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Get.back();
      
      Get.snackbar(
        'خطأ',
        'حدث خطأ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
