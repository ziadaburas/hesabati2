import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/data/services/firebase_service.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/search_users_screen.dart';

/// شاشة إنشاء حساب مشترك
class CreateSharedAccountScreen extends StatefulWidget {
  const CreateSharedAccountScreen({super.key});

  @override
  State<CreateSharedAccountScreen> createState() => _CreateSharedAccountScreenState();
}

class _CreateSharedAccountScreenState extends State<CreateSharedAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final PageController _pageController = PageController();
  
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = FirebaseService.instance;

  int _currentStep = 0;
  UserEntity? _selectedUser;
  String _selectedAccountType = AppConstants.accountTypeLoan;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب مشترك'),
      ),
      body: Column(
        children: [
          // مؤشر الخطوات
          _buildStepIndicator(),
          
          // محتوى الخطوات
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          
          // أزرار التنقل
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          _buildStepCircle(0, 'اختيار المستخدم'),
          Expanded(child: _buildStepLine(0)),
          _buildStepCircle(1, 'بيانات الحساب'),
          Expanded(child: _buildStepLine(1)),
          _buildStepCircle(2, 'التأكيد'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isComplete = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isComplete = _currentStep > step;
    
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isComplete ? AppColors.primary : Colors.grey[300],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخطوة 1: اختيار المستخدم',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابحث عن المستخدم الذي تريد إنشاء حساب مشترك معه',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          if (_selectedUser != null) ...[
            // المستخدم المحدد
            Card(
              color: AppColors.success.withOpacity(0.1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _selectedUser!.profilePictureUrl != null
                      ? NetworkImage(_selectedUser!.profilePictureUrl!)
                      : null,
                  child: _selectedUser!.profilePictureUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                title: Text(
                  _selectedUser!.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_selectedUser!.email),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: () {
                    setState(() => _selectedUser = null);
                  },
                ),
              ),
            ),
          ] else ...[
            // زر البحث عن مستخدم
            Card(
              child: InkWell(
                onTap: _searchForUser,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.person_search, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'البحث عن مستخدم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط هنا للبحث عن مستخدم بالبريد الإلكتروني',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الخطوة 2: بيانات الحساب',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل بيانات الحساب المشترك',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // اسم الحساب
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الحساب',
                hintText: 'مثال: حساب مشتريات المحل',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم الحساب';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // نوع الحساب
            const Text(
              'نوع الحساب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAccountTypeChip(AppConstants.accountTypeLoan, 'دين', AppColors.loan),
                _buildAccountTypeChip(AppConstants.accountTypeDebt, 'مديونية', AppColors.debt),
                _buildAccountTypeChip(AppConstants.accountTypeSavings, 'توفير', AppColors.savings),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeChip(String type, String label, Color color) {
    final isSelected = _selectedAccountType == type;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedAccountType = type);
        }
      },
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخطوة 3: تأكيد الطلب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'راجع البيانات وأرسل الطلب',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // ملخص الطلب
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow('المستخدم', _selectedUser?.username ?? '-'),
                  const Divider(),
                  _buildSummaryRow('البريد الإلكتروني', _selectedUser?.email ?? '-'),
                  const Divider(),
                  _buildSummaryRow('اسم الحساب', _accountNameController.text),
                  const Divider(),
                  _buildSummaryRow('نوع الحساب', _getAccountTypeLabel(_selectedAccountType)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ملاحظة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'سيتم إرسال طلب للمستخدم الآخر للموافقة على إنشاء الحساب المشترك',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('السابق'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 2 ? 'إرسال الطلب' : 'التالي'),
            ),
          ),
        ],
      ),
    );
  }

  void _searchForUser() async {
    final result = await Get.to(() => const SearchUsersScreen());
    if (result != null && result is UserEntity) {
      setState(() => _selectedUser = result);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_selectedUser == null) {
        Get.snackbar(
          'تنبيه',
          'يرجى اختيار مستخدم أولاً',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentStep == 2) {
      await _submitRequest();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);

    try {
      final request = AccountRequestEntity(
        requestId: const Uuid().v4(),
        fromUserId: _authController.currentUserId,
        toUserId: _selectedUser!.userId,
        accountName: _accountNameController.text,
        accountType: _selectedAccountType,
        requestStatus: AppConstants.requestStatusPending,
        createdAt: DateTime.now(),
      );

      final result = await _firebaseService.createAccountRequest(request);
      
      if (result != null) {
        Get.back(result: true);
        Get.snackbar(
          'نجح',
          'تم إرسال الطلب بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء إرسال الطلب',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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
}
