import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/dashboard_screen.dart';

/// شاشة إكمال البيانات بعد تسجيل الدخول عبر Google
class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key});

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تعبئة البيانات من حساب Google
    final user = _authController.currentUser.value;
    if (user != null) {
      _usernameController.text = user.username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إكمال البيانات'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // صورة المستخدم
                _buildProfileImage(),
                const SizedBox(height: 24),

                // البريد الإلكتروني (للعرض فقط)
                _buildEmailField(),
                const SizedBox(height: 16),

                // اسم المستخدم
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    hintText: 'أدخل اسم المستخدم',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المستخدم';
                    }
                    if (value.length < 3) {
                      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // رقم الهاتف
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    hintText: '05xxxxxxxx',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // التحقق من صيغة رقم الهاتف
                      final phoneRegex = RegExp(r'^05\d{8}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'صيغة رقم الهاتف غير صحيحة';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ملاحظة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يمكنك تعديل هذه البيانات لاحقاً من الإعدادات',
                          style: TextStyle(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // زر المتابعة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('متابعة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final user = _authController.currentUser.value;
    final profileUrl = user?.profilePictureUrl;

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null
              ? const Icon(Icons.person, size: 50, color: AppColors.primary)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    final user = _authController.currentUser.value;
    
    return TextFormField(
      initialValue: user?.email ?? '',
      enabled: false,
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني',
        prefixIcon: const Icon(Icons.email),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // تحديث بيانات المستخدم
      final currentUser = _authController.currentUser.value;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          username: _usernameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          updatedAt: DateTime.now(),
        );

        // TODO: حفظ البيانات في Firebase
        _authController.currentUser.value = updatedUser;
      }

      // الانتقال إلى لوحة التحكم
      Get.offAll(() => const DashboardScreen());
      
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
