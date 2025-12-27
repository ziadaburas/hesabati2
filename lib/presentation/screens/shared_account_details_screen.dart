import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/data/services/connectivity_service.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/shared_transaction_form_screen.dart';

/// شاشة تفاصيل الحساب المشترك
class SharedAccountDetailsScreen extends StatefulWidget {
  final String accountId;

  const SharedAccountDetailsScreen({super.key, required this.accountId});

  @override
  State<SharedAccountDetailsScreen> createState() => _SharedAccountDetailsScreenState();
}

class _SharedAccountDetailsScreenState extends State<SharedAccountDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  AccountEntity? _account;
  List<SharedTransactionEntity> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      // تحميل بيانات الحساب
      _account = await _firebaseService.getSharedAccountById(widget.accountId);
      
      // تحميل العمليات
      _transactions = await _firebaseService.getSharedAccountTransactions(widget.accountId);
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحساب المشترك')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحساب المشترك')),
        body: const Center(child: Text('الحساب غير موجود')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_account!.accountName),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'معتمدة'),
            Tab(text: 'قيد الانتظار'),
            Tab(text: 'مرفوضة'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildAccountHeader(),
            _buildStatisticsSection(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionsList(null), // الكل
                  _buildTransactionsList(AppConstants.sharedTransactionStatusApproved),
                  _buildTransactionsList(AppConstants.sharedTransactionStatusPendingApproval),
                  _buildTransactionsList(AppConstants.sharedTransactionStatusRejected),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('عملية جديدة'),
      ),
    );
  }

  Widget _buildAccountHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.shared, AppColors.shared.withOpacity(0.7)],
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
              'مع: ${_account!.otherPartyName}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // حالة الاتصال
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _connectivityService.isConnected.value 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _connectivityService.isConnected.value 
                      ? Icons.cloud_done 
                      : Icons.cloud_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _connectivityService.isConnected.value 
                      ? 'متصل' 
                      : 'غير متصل',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    // حساب الإحصائيات
    final approvedTransactions = _transactions
        .where((t) => t.isApproved)
        .toList();
    
    double totalIn = 0.0;
    double totalOut = 0.0;
    
    for (final t in approvedTransactions) {
      if (t.isIncoming) {
        totalIn += t.amount;
      } else {
        totalOut += t.amount;
      }
    }

    final pendingCount = _transactions
        .where((t) => t.isPendingApproval)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.arrow_downward,
              title: 'إجمالي الوارد',
              value: '${totalIn.toStringAsFixed(2)}',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              icon: Icons.arrow_upward,
              title: 'إجمالي الصادر',
              value: '${totalOut.toStringAsFixed(2)}',
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending,
              title: 'قيد الانتظار',
              value: '$pendingCount',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(String? statusFilter) {
    List<SharedTransactionEntity> filteredTransactions;
    
    if (statusFilter == null) {
      filteredTransactions = _transactions;
    } else {
      filteredTransactions = _transactions
          .where((t) => t.sharedStatus == statusFilter)
          .toList();
    }

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد عمليات',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(filteredTransactions[index]);
      },
    );
  }

  Widget _buildTransactionItem(SharedTransactionEntity transaction) {
    final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
    final isIncoming = transaction.isIncoming;
    final isCurrentUserCreator = transaction.createdByUserId == _authController.currentUserId;
    final needsMyApproval = transaction.isPendingApproval && !isCurrentUserCreator;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // أيقونة نوع العملية
                  CircleAvatar(
                    backgroundColor: (isIncoming ? AppColors.success : AppColors.error).withOpacity(0.1),
                    child: Icon(
                      isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncoming ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // تفاصيل العملية
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description.isEmpty 
                              ? transaction.transactionTypeLabel 
                              : transaction.description,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              isCurrentUserCreator 
                                  ? 'أنشأتها أنت' 
                                  : 'بواسطة: ${transaction.createdByUserName ?? 'مستخدم'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(transaction.transactionDate),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  
                  // المبلغ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncoming ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIncoming ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(transaction.sharedStatus),
                    ],
                  ),
                ],
              ),
              
              // أزرار الموافقة/الرفض إذا كانت العملية تحتاج موافقة
              if (needsMyApproval) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectTransaction(transaction),
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
                        onPressed: () => _approveTransaction(transaction),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        child: const Text('موافقة'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case AppConstants.sharedTransactionStatusOffline:
        color = Colors.grey;
        label = 'أوفلاين';
        icon = Icons.cloud_off;
        break;
      case AppConstants.sharedTransactionStatusPendingApproval:
        color = AppColors.warning;
        label = 'قيد الانتظار';
        icon = Icons.pending;
        break;
      case AppConstants.sharedTransactionStatusApproved:
        color = AppColors.success;
        label = 'معتمدة';
        icon = Icons.check_circle;
        break;
      case AppConstants.sharedTransactionStatusRejected:
        color = AppColors.error;
        label = 'مرفوضة';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(SharedTransactionEntity transaction) {
    final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تفاصيل العملية',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildStatusBadge(transaction.sharedStatus),
                ],
              ),
              const Divider(height: 24),
              
              // المبلغ
              _buildDetailRow(
                'المبلغ',
                '${transaction.amount.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
                transaction.isIncoming ? AppColors.success : AppColors.error,
              ),
              
              // النوع
              _buildDetailRow('النوع', transaction.transactionTypeLabel, null),
              
              // الوصف
              if (transaction.description.isNotEmpty)
                _buildDetailRow('الوصف', transaction.description, null),
              
              // الملاحظات
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('ملاحظات', transaction.notes!, null),
              
              // التاريخ
              _buildDetailRow('التاريخ', dateFormat.format(transaction.transactionDate), null),
              
              // منشئ العملية
              _buildDetailRow(
                'أنشأها',
                transaction.createdByUserName ?? 'مستخدم',
                null,
              ),
              
              // سبب الرفض إن وجد
              if (transaction.isRejected && transaction.rejectionReason != null)
                _buildDetailRow('سبب الرفض', transaction.rejectionReason!, AppColors.error),
              
              // وقت الموافقة إن وجد
              if (transaction.isApproved && transaction.approvedAt != null)
                _buildDetailRow(
                  'وقت الموافقة',
                  dateFormat.format(transaction.approvedAt!),
                  AppColors.success,
                ),
              
              const SizedBox(height: 16),
              
              // زر الإغلاق
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTransaction() async {
    if (_account == null) return;
    
    final result = await Get.to(() => SharedTransactionFormScreen(
      account: _account!,
    ));
    
    if (result == true) {
      await _loadData();
    }
  }

  void _approveTransaction(SharedTransactionEntity transaction) async {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل تريد الموافقة على هذه العملية بمبلغ ${transaction.amount} ${AppConstants.currencySymbol}؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // عرض مؤشر التحميل
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              
              try {
                final success = await _firebaseService.approveSharedTransaction(
                  transaction.transactionId,
                  _authController.currentUserId,
                );
                
                Get.back(); // إغلاق مؤشر التحميل
                
                if (success) {
                  Get.snackbar(
                    'نجح',
                    'تمت الموافقة على العملية',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                  await _loadData();
                } else {
                  Get.snackbar(
                    'خطأ',
                    'حدث خطأ أثناء الموافقة على العملية',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.error,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.back();
                Get.snackbar(
                  'خطأ',
                  'حدث خطأ: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _rejectTransaction(SharedTransactionEntity transaction) {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('رفض العملية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد رفض هذه العملية بمبلغ ${transaction.amount} ${AppConstants.currencySymbol}؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                hintText: 'أدخل سبب الرفض...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // عرض مؤشر التحميل
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              
              try {
                final success = await _firebaseService.rejectSharedTransaction(
                  transaction.transactionId,
                  _authController.currentUserId,
                  reasonController.text.isEmpty ? null : reasonController.text,
                );
                
                Get.back(); // إغلاق مؤشر التحميل
                
                if (success) {
                  Get.snackbar(
                    'نجح',
                    'تم رفض العملية',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.warning,
                    colorText: Colors.white,
                  );
                  await _loadData();
                } else {
                  Get.snackbar(
                    'خطأ',
                    'حدث خطأ أثناء رفض العملية',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.error,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.back();
                Get.snackbar(
                  'خطأ',
                  'حدث خطأ: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
