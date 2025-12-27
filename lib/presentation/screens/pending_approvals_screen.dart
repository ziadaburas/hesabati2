import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة الموافقات المعلقة - تعرض طلبات الحسابات والعمليات التي تحتاج موافقة
class PendingApprovalsScreen extends StatefulWidget {
  final List<AccountRequestEntity> pendingRequests;
  final List<SharedTransactionEntity> pendingTransactions;

  const PendingApprovalsScreen({
    super.key,
    required this.pendingRequests,
    required this.pendingTransactions,
  });

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  late List<AccountRequestEntity> _pendingRequests;
  late List<SharedTransactionEntity> _pendingTransactions;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingRequests = List.from(widget.pendingRequests);
    _pendingTransactions = List.from(widget.pendingTransactions);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop && _hasChanges) {
          // لا نحتاج لفعل شيء هنا، سنعيد true في WillPopScope
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الموافقات المعلقة'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(result: _hasChanges),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('العمليات'),
                    if (_pendingTransactions.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pendingTransactions.length}',
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
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('الحسابات'),
                    if (_pendingRequests.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTransactionsTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_pendingTransactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'لا توجد عمليات معلقة',
        subtitle: 'ستظهر هنا العمليات التي تحتاج موافقتك',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingTransactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(_pendingTransactions[index], index);
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'لا توجد طلبات معلقة',
        subtitle: 'ستظهر هنا طلبات الحسابات المشتركة الواردة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(_pendingRequests[index], index);
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

  Widget _buildTransactionCard(SharedTransactionEntity transaction, int index) {
    final dateFormat = DateFormat(AppConstants.dateTimeFormatDisplay);
    final isIncoming = transaction.isIncoming;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isIncoming ? AppColors.success : AppColors.error).withOpacity(0.1),
                  child: Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncoming ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description.isEmpty 
                            ? 'عملية ${transaction.transactionTypeLabel}'
                            : transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'من: ${transaction.createdByUserName ?? 'مستخدم'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncoming ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isIncoming ? AppColors.success : AppColors.error,
                      ),
                    ),
                    Text(
                      AppConstants.currencySymbol,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // التاريخ
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(transaction.transactionDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            
            // الملاحظات
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // أزرار الموافقة والرفض
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectTransaction(transaction, index),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveTransaction(transaction, index),
                    icon: const Icon(Icons.check),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AccountRequestEntity request, int index) {
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
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.people, color: AppColors.primary),
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
                        'طلب من: ${request.fromUserName ?? request.fromUserEmail ?? request.fromUserId}',
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
                  child: OutlinedButton.icon(
                    onPressed: () => _respondToRequest(request, false, index),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToRequest(request, true, index),
                    icon: const Icon(Icons.check),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _approveTransaction(SharedTransactionEntity transaction, int index) async {
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
              await _processTransactionApproval(transaction, index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTransactionApproval(SharedTransactionEntity transaction, int index) async {
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
        setState(() {
          _pendingTransactions.removeAt(index);
          _hasChanges = true;
        });
        
        Get.snackbar(
          'نجح',
          'تمت الموافقة على العملية',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
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
  }

  void _rejectTransaction(SharedTransactionEntity transaction, int index) {
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
              await _processTransactionRejection(transaction, index, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  Future<void> _processTransactionRejection(
    SharedTransactionEntity transaction,
    int index,
    String? reason,
  ) async {
    // عرض مؤشر التحميل
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      final success = await _firebaseService.rejectSharedTransaction(
        transaction.transactionId,
        _authController.currentUserId,
        reason?.isEmpty == true ? null : reason,
      );
      
      Get.back(); // إغلاق مؤشر التحميل
      
      if (success) {
        setState(() {
          _pendingTransactions.removeAt(index);
          _hasChanges = true;
        });
        
        Get.snackbar(
          'تم',
          'تم رفض العملية',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
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
  }

  void _respondToRequest(AccountRequestEntity request, bool accept, int index) async {
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
        setState(() {
          _pendingRequests.removeAt(index);
          _hasChanges = true;
        });
        
        Get.snackbar(
          'نجح',
          accept ? 'تم قبول الطلب وإنشاء الحساب المشترك' : 'تم رفض الطلب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
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
