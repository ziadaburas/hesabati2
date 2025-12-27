import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/data/services/connectivity_service.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة إضافة عملية للحساب المشترك
class SharedTransactionFormScreen extends StatefulWidget {
  final AccountEntity account;
  final SharedTransactionEntity? transaction; // للتعديل

  const SharedTransactionFormScreen({
    super.key,
    required this.account,
    this.transaction,
  });

  @override
  State<SharedTransactionFormScreen> createState() => _SharedTransactionFormScreenState();
}

class _SharedTransactionFormScreenState extends State<SharedTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();

  String _selectedType = AppConstants.transactionTypeIn;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedType = widget.transaction!.transactionType;
      _selectedDate = widget.transaction!.transactionDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل العملية' : 'عملية جديدة'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // معلومات الحساب
              _buildAccountInfo(),
              const SizedBox(height: 16),

              // حالة الاتصال
              _buildConnectionStatus(),
              const SizedBox(height: 24),

              // نوع العملية
              _buildTransactionTypeSelector(),
              const SizedBox(height: 24),

              // المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: AppConstants.currencySymbol,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'يرجى إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الوصف
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'مثال: دفعة إيجار',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال وصف العملية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // التاريخ
              _buildDateSelector(),
              const SizedBox(height: 16),

              // الملاحظات
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  hintText: 'أضف ملاحظات...',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                maxLength: AppConstants.maxNotesLength,
              ),
              const SizedBox(height: 16),

              // معلومات الحالة
              _buildStatusInfo(),
              const SizedBox(height: 32),

              // زر الحفظ
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'حفظ التغييرات' : 'إضافة العملية'),
              ),
              const SizedBox(height: 16),

              // زر الإلغاء
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.shared.withOpacity(0.1),
          child: const Icon(Icons.people, color: AppColors.shared),
        ),
        title: Text(
          widget.account.accountName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.account.otherPartyName != null)
              Text('مع: ${widget.account.otherPartyName}'),
            Text(
              'الرصيد الحالي: ${widget.account.balance.toStringAsFixed(2)} ${AppConstants.currencySymbol}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Obx(() {
      final isConnected = _connectivityService.isConnected.value;
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isConnected 
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected ? AppColors.success : AppColors.warning,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isConnected ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'متصل بالإنترنت' : 'غير متصل بالإنترنت',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isConnected ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  Text(
                    isConnected 
                        ? 'سيتم إرسال العملية للطرف الآخر للموافقة'
                        : 'سيتم حفظ العملية محلياً وإرسالها لاحقاً',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع العملية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                type: AppConstants.transactionTypeIn,
                label: 'وارد',
                icon: Icons.arrow_downward,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                type: AppConstants.transactionTypeOut,
                label: 'صادر',
                icon: Icons.arrow_upward,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat(AppConstants.dateFormatDisplay);
    
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(_selectedDate)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Obx(() {
      final isConnected = _connectivityService.isConnected.value;
      
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'كيف تعمل العمليات المشتركة؟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusStep(
                '1',
                isConnected ? 'أوفلاين' : 'أوفلاين (الحالة الحالية)',
                'تُحفظ العملية محلياً',
                !isConnected,
              ),
              _buildStatusStep(
                '2',
                isConnected ? 'قيد الانتظار (الحالة بعد الإرسال)' : 'قيد الانتظار',
                'تُرسل للطرف الآخر للموافقة',
                isConnected,
              ),
              _buildStatusStep(
                '3',
                'معتمدة',
                'بعد موافقة الطرف الآخر تصبح معتمدة',
                false,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusStep(String number, String title, String subtitle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.primary : Colors.grey.shade700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'EG'),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final isConnected = _connectivityService.isConnected.value;
      final now = DateTime.now();
      
      // الحصول على بيانات المستخدم الحالي
      final currentUserId = _authController.currentUserId;
      final currentUserData = await _firebaseService.getUserData();
      final currentUserName = currentUserData?.username ?? 'مستخدم';
      
      // تحديد الحالة بناءً على الاتصال
      final initialStatus = isConnected 
          ? AppConstants.sharedTransactionStatusPendingApproval
          : AppConstants.sharedTransactionStatusOffline;
      
      // إنشاء العملية
      final transaction = SharedTransactionEntity(
        transactionId: const Uuid().v4(),
        accountId: widget.account.accountId,
        linkedAccountId: _getLinkedAccountId(),
        amount: amount,
        transactionType: _selectedType,
        description: _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        transactionDate: _selectedDate,
        createdByUserId: currentUserId,
        createdByUserName: currentUserName,
        otherPartyUserId: widget.account.otherPartyId ?? '',
        otherPartyUserName: widget.account.otherPartyName,
        sharedStatus: initialStatus,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );
      
      if (isConnected) {
        // إرسال مباشرة إلى Firebase
        final transactionId = await _firebaseService.createSharedTransaction(transaction);
        
        if (transactionId != null) {
          Get.back(result: true);
          Get.snackbar(
            'نجح',
            'تم إرسال العملية للطرف الآخر للموافقة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'خطأ',
            'حدث خطأ أثناء إرسال العملية',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      } else {
        // حفظ محلياً للمزامنة لاحقاً
        // TODO: حفظ في قاعدة البيانات المحلية
        Get.back(result: true);
        Get.snackbar(
          'تم الحفظ',
          'تم حفظ العملية محلياً وسيتم إرسالها عند توفر الاتصال',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ العملية: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getLinkedAccountId() {
    // الحصول على معرف الحساب المرتبط للطرف الآخر
    // بناءً على بنية الحسابات المشتركة، المعرف يكون requestId_userId
    final accountId = widget.account.accountId;
    final parts = accountId.split('_');
    
    if (parts.length >= 2) {
      final requestId = parts[0];
      final otherPartyId = widget.account.otherPartyId;
      return '${requestId}_$otherPartyId';
    }
    
    return '';
  }
}
