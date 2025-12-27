import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/controllers.dart';
import '/data/services/database_service.dart';
import '/presentation/screens/edit_profile_screen.dart';
import '/presentation/screens/sync_status_screen.dart';
import '/presentation/screens/reports_screen.dart';
import '/presentation/screens/initial_choice_screen.dart';
import '/presentation/screens/change_password_screen.dart';

/// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final settingsController = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        children: [
          // معلومات المستخدم
          _buildUserSection(authController),
          const Divider(height: 1),

          // إعدادات التطبيق
          _buildSettingsSection(settingsController),
          const Divider(height: 1),

          // الأدوات
          _buildToolsSection(authController),
          const Divider(height: 1),

          // حول التطبيق
          _buildAboutSection(),
          const Divider(height: 1),

          // تسجيل الخروج
          _buildLogoutSection(authController),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserSection(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      final isAuthenticated = authController.isAuthenticatedMode;
      
      return ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: user?.profilePictureUrl != null
              ? NetworkImage(user!.profilePictureUrl!)
              : null,
          child: user?.profilePictureUrl == null
              ? const Icon(Icons.person, size: 30, color: AppColors.primary)
              : null,
        ),
        title: Text(
          user?.username ?? 'local_mode'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user?.email != null && user!.email.isNotEmpty)
              Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isAuthenticated ? AppColors.success : AppColors.warning)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAuthenticated ? 'online_mode'.tr : 'local_mode'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: isAuthenticated ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => const EditProfileScreen()),
      );
    });
  }

  Widget _buildSettingsSection(SettingsController settingsController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'settings'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // اللغة
        Obx(() => ListTile(
          leading: const Icon(Icons.language),
          title: Text('language'.tr),
          subtitle: Text(settingsController.currentLanguageLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(settingsController),
        )),

        // الثيم
        Obx(() => ListTile(
          leading: const Icon(Icons.palette),
          title: Text('theme'.tr),
          subtitle: Text(settingsController.currentThemeLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(settingsController),
        )),

        // الإشعارات
        Obx(() => SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: Text('notifications_enabled'.tr),
          value: settingsController.notificationsEnabled.value,
          onChanged: (_) => settingsController.toggleNotifications(),
        )),

        // الصوت
        Obx(() => SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: Text('sounds_enabled'.tr),
          value: settingsController.soundEnabled.value,
          onChanged: (_) => settingsController.toggleSound(),
        )),
      ],
    );
  }

  Widget _buildToolsSection(AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'reports'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // تغيير كلمة المرور (للمستخدمين المسجلين فقط)
        if (authController.isAuthenticatedMode)
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('change_password'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const ChangePasswordScreen()),
          ),

        // حالة المزامنة
        if (authController.isAuthenticatedMode)
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text('sync_status'.tr),
            subtitle: Text('last_sync'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const SyncStatusScreen()),
          ),

        // التقارير
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: Text('reports'.tr),
          subtitle: Text('account_summary'.tr),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Get.to(() => const ReportsScreen()),
        ),

        // حذف البيانات
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: Text(
            'delete_all_data'.tr,
            style: const TextStyle(color: AppColors.error),
          ),
          subtitle: Text('confirm_delete_all'.tr.split('\n').first),
          trailing: const Icon(Icons.chevron_right, color: AppColors.error),
          onTap: () => _confirmDeleteAllData(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'about'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.info),
          title: Text('about'.tr),
          subtitle: Text('${AppConstants.appNameAr} v${AppConstants.appVersion}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(),
        ),

        ListTile(
          leading: const Icon(Icons.policy),
          title: Text('privacy_policy'.tr),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح سياسة الخصوصية
          },
        ),

        ListTile(
          leading: const Icon(Icons.article),
          title: Text('terms_of_service'.tr),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح شروط الاستخدام
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(AuthController authController) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(authController),
        icon: const Icon(Icons.logout),
        label: Text(authController.isAuthenticatedMode
            ? 'logout'.tr
            : 'logout'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showLanguageDialog(SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: AppConstants.languageArabic,
              groupValue: controller.language.value,
              onChanged: (value) {
                controller.changeLanguage(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: AppConstants.languageEnglish,
              groupValue: controller.language.value,
              onChanged: (value) {
                controller.changeLanguage(value!);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('theme'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('theme_light'.tr),
              secondary: const Icon(Icons.light_mode),
              value: 'light',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: Text('theme_dark'.tr),
              secondary: const Icon(Icons.dark_mode),
              value: 'dark',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: Text('theme_system'.tr),
              secondary: const Icon(Icons.settings_brightness),
              value: 'system',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAllData() {
    Get.dialog(
      AlertDialog(
        title: Text('confirm_delete'.tr),
        content: Text('confirm_delete_all'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await DatabaseService.instance.clearAllData();
              Get.snackbar(
                'success'.tr,
                'data_deleted'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
              );
              // تحديث البيانات
              Get.find<LocalAccountController>().fetchLocalAccounts();
            },
            child: Text('delete'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text('app_name'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppConstants.appVersion}'),
            const SizedBox(height: 16),
            Text('app_subtitle'.tr),
            const SizedBox(height: 16),
            Text(
              '© 2024',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: Text('confirm'.tr),
        content: Text('confirm_logout'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await authController.signOut();
              Get.offAll(() => const InitialChoiceScreen());
            },
            child: Text(
              'logout'.tr,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
