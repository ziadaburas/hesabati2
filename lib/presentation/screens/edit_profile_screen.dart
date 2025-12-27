import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/presentation/controllers/controllers.dart';

/// شاشة تعديل الملف الشخصي
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _authController.currentUser.value;
    if (user != null) {
      _usernameController.text = user.username;
      _phoneController.text = user.phone ?? '';
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
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'حفظ',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // صورة الملف الشخصي
              _buildProfileImage(),
              const SizedBox(height: 32),

              // البريد الإلكتروني (للعرض فقط)
              _buildEmailField(),
              const SizedBox(height: 16),

              // اسم المستخدم
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
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
                    final phoneRegex = RegExp(r'^05\d{8}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'صيغة رقم الهاتف غير صحيحة';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // معلومات الحساب
              _buildAccountInfo(),
            ],
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
          radius: 60,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null
              ? const Icon(Icons.person, size: 60, color: AppColors.primary)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _changeProfileImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
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
        helperText: 'لا يمكن تعديل البريد الإلكتروني',
      ),
    );
  }

  Widget _buildAccountInfo() {
    final user = _authController.currentUser.value;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الحساب',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('نوع الحساب', 
                _authController.isAuthenticatedMode ? 'حساب مفعل' : 'وضع محلي'),
            const Divider(),
            _buildInfoRow('تاريخ الإنشاء', 
                user?.createdAt.toString().split(' ')[0] ?? '-'),
            const Divider(),
            _buildInfoRow('آخر تحديث', 
                user?.updatedAt.toString().split(' ')[0] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _changeProfileImage() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تغيير صورة الملف الشخصي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOptionButton(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () {
                    Get.back();
                    // TODO: فتح الكاميرا
                  },
                ),
                _buildImageOptionButton(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  onTap: () {
                    Get.back();
                    // TODO: فتح المعرض
                  },
                ),
                if (_authController.currentUser.value?.profilePictureUrl != null)
                  _buildImageOptionButton(
                    icon: Icons.delete,
                    label: 'حذف',
                    color: AppColors.error,
                    onTap: () {
                      Get.back();
                      // TODO: حذف الصورة
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authController.currentUser.value;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          username: _usernameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          updatedAt: DateTime.now(),
        );

        // TODO: حفظ البيانات في Firebase/قاعدة البيانات المحلية
        _authController.currentUser.value = updatedUser;

        Get.back();
        Get.snackbar(
          'نجح',
          'تم تحديث الملف الشخصي بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
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
