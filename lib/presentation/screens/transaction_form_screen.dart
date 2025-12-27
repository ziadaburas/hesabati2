import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة إضافة/تعديل عملية
class TransactionFormScreen extends StatefulWidget {
  final String accountId;
  final TransactionEntity? transaction;

  const TransactionFormScreen({
    super.key,
    required this.accountId,
    this.transaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  final TransactionController _transactionController = Get.find<TransactionController>();

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

              // زر الحذف (للتعديل فقط)
              if (_isEdit) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _confirmDelete,
                  child: const Text(
                    'حذف العملية',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
      
      if (_isEdit) {
        // تحديث العملية
        final updatedTransaction = widget.transaction!.copyWith(
          amount: amount,
          transactionType: _selectedType,
          description: _descriptionController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          transactionDate: _selectedDate,
          updatedAt: DateTime.now(),
        );

        final success = await _transactionController.updateTransaction(updatedTransaction);
        
        if (success) {
          Get.back(result: true);
          Get.snackbar(
            'نجح',
            'تم تحديث العملية بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'خطأ',
            _transactionController.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      } else {
        // إنشاء عملية جديدة
        final newTransaction = _transactionController.createNewTransaction(
          accountId: widget.accountId,
          amount: amount,
          transactionType: _selectedType,
          description: _descriptionController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          transactionDate: _selectedDate,
        );

        final success = await _transactionController.createTransaction(newTransaction);
        
        if (success) {
          Get.back(result: true);
          Get.snackbar(
            'نجح',
            'تم إضافة العملية بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'خطأ',
            _transactionController.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
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

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text('هل أنت متأكد من حذف هذه العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await _transactionController.deleteTransaction(
                widget.transaction!.transactionId,
              );
              if (success) {
                Get.back(result: true);
                Get.snackbar(
                  'نجح',
                  'تم حذف العملية بنجاح',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
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
