import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import '/data/services/database_service.dart';
import '/presentation/controllers/auth_controller.dart';
import '/presentation/controllers/local_account_controller.dart';

class AccountFormScreen extends StatefulWidget {
  final Map<String, dynamic>? account;
  
  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _otherPartyController = TextEditingController();
  final _balanceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = AppConstants.accountTypeLoan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!['account_name'] ?? '';
      _otherPartyController.text = widget.account!['other_party_name'] ?? '';
      _balanceController.text = widget.account!['balance']?.toString() ?? '0';
      _selectedType = widget.account!['account_type'] ?? AppConstants.accountTypeLoan;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _otherPartyController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل الحساب' : 'حساب جديد'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحساب',
                  hintText: 'مثال: حساب المشتريات',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الحساب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Account Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحساب',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.accountTypeLoan,
                    child: Text('دين (Loan)'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.accountTypeDebt,
                    child: Text('مديونية (Debt)'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.accountTypeSavings,
                    child: Text('توفير (Savings)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Other Party Name
              TextFormField(
                controller: _otherPartyController,
                decoration: const InputDecoration(
                  labelText: 'اسم الطرف الآخر',
                  hintText: 'مثال: أحمد محمد',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Initial Balance
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'الرصيد الأولي',
                  hintText: '0',
                  prefixIcon: Icon(Icons.money),
                  suffixText: 'ر.س',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
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
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'حفظ التغييرات' : 'إنشاء الحساب'),
              ),
              const SizedBox(height: 16),
              
              // Cancel Button
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

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على userId الفعلي من AuthController
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;
      
      final now = DateTime.now().toIso8601String();
      
      // عند التعديل، نحافظ على الرصيد الحالي إذا كان هناك عمليات
      double balance;
      if (widget.account != null) {
        // الحصول على الرصيد الحالي من العمليات
        final accountController = Get.find<LocalAccountController>();
        final existingAccount = await accountController.getAccountById(widget.account!['account_id']);
        if (existingAccount != null) {
          // نحافظ على الرصيد المحسوب من العمليات
          balance = existingAccount.balance;
        } else {
          balance = double.tryParse(_balanceController.text) ?? 0.0;
        }
      } else {
        balance = double.tryParse(_balanceController.text) ?? 0.0;
      }
      
      final accountData = {
        'account_id': widget.account?['account_id'] ?? const Uuid().v4(),
        'user_id': userId,
        'account_name': _nameController.text,
        'account_type': _selectedType,
        'account_category': AppConstants.accountCategoryLocal,
        'balance': balance,
        'currency': AppConstants.defaultCurrency,
        'other_party_name': _otherPartyController.text.isNotEmpty ? _otherPartyController.text : null,
        'account_status': AppConstants.accountStatusActive,
        'created_by': userId,
        'created_at': widget.account?['created_at'] ?? now,
        'updated_at': now,
        'is_synced': 0,
        'sync_status': AppConstants.syncStatusOffline,
      };

      if (widget.account == null) {
        // إنشاء حساب جديد - هنا نستخدم الرصيد الأولي المدخل
        accountData['balance'] = double.tryParse(_balanceController.text) ?? 0.0;
        await DatabaseService.instance.insert('accounts', accountData);
        
        // إذا كان هناك رصيد أولي، نضيف عملية وارد
        final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
        if (initialBalance > 0) {
          final transactionData = {
            'transaction_id': const Uuid().v4(),
            'account_id': accountData['account_id'],
            'amount': initialBalance,
            'transaction_type': AppConstants.transactionTypeIn,
            'description': 'رصيد أولي',
            'notes': null,
            'transaction_date': now,
            'recorded_by_user': userId,
            'approved_by_user': null,
            'status': AppConstants.transactionStatusCompleted,
            'transaction_status': AppConstants.syncStatusOffline,
            'created_at': now,
            'updated_at': now,
            'is_synced': 0,
          };
          await DatabaseService.instance.insert('transactions', transactionData);
        }
        
        Get.snackbar(
          'نجح',
          'تم إنشاء الحساب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        // تحديث الحساب الموجود
        await DatabaseService.instance.update(
          'accounts',
          accountData,
          where: 'account_id = ?',
          whereArgs: [widget.account!['account_id']],
        );
        
        Get.snackbar(
          'نجح',
          'تم تحديث الحساب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }

      // تحديث قائمة الحسابات
      final accountController = Get.find<LocalAccountController>();
      await accountController.fetchLocalAccounts();

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ الحساب: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
