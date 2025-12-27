import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// وحدة التحكم في الإعدادات
class SettingsController extends GetxController {
  // Properties
  final language = AppConstants.languageArabic.obs;
  final themeMode = 'light'.obs;
  final notificationsEnabled = true.obs;
  final soundEnabled = true.obs;
  final isLoading = false.obs;

  // Keys for SharedPreferences
  static const String _keyLanguage = 'settings_language';
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyNotifications = 'settings_notifications';
  static const String _keySound = 'settings_sound';

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// تحميل الإعدادات المحفوظة
  Future<void> loadSettings() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

      language.value = prefs.getString(_keyLanguage) ?? AppConstants.languageArabic;
      themeMode.value = prefs.getString(_keyThemeMode) ?? 'light';
      notificationsEnabled.value = prefs.getBool(_keyNotifications) ?? true;
      soundEnabled.value = prefs.getBool(_keySound) ?? true;

      // تطبيق الإعدادات
      _applyLanguage();
      _applyTheme();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Load settings error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ الإعدادات
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language.value);
      await prefs.setString(_keyThemeMode, themeMode.value);
      await prefs.setBool(_keyNotifications, notificationsEnabled.value);
      await prefs.setBool(_keySound, soundEnabled.value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Save settings error: $e');
      }
    }
  }

  /// تغيير اللغة
  Future<void> changeLanguage(String languageCode) async {
    language.value = languageCode;
    _applyLanguage();
    await saveSettings();
  }

  /// تطبيق اللغة
  void _applyLanguage() {
    Locale locale;
    if (language.value == AppConstants.languageArabic) {
      locale = const Locale('ar', 'EG');
    } else {
      locale = const Locale('en', 'US');
    }
    Get.updateLocale(locale);
  }

  /// تغيير الثيم
  Future<void> changeTheme(String mode) async {
    themeMode.value = mode;
    _applyTheme();
    await saveSettings();
  }

  /// تطبيق الثيم
  void _applyTheme() {
    switch (themeMode.value) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      case 'system':
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }

  /// تبديل الإشعارات
  Future<void> toggleNotifications() async {
    notificationsEnabled.value = !notificationsEnabled.value;
    await saveSettings();
  }

  /// تبديل الصوت
  Future<void> toggleSound() async {
    soundEnabled.value = !soundEnabled.value;
    await saveSettings();
  }

  /// الحصول على تسمية اللغة الحالية
  String get currentLanguageLabel {
    return language.value == AppConstants.languageArabic ? 'العربية' : 'English';
  }

  /// الحصول على تسمية الثيم الحالي
  String get currentThemeLabel {
    switch (themeMode.value) {
      case 'light':
        return 'فاتح';
      case 'dark':
        return 'داكن';
      case 'system':
        return 'النظام';
      default:
        return themeMode.value;
    }
  }

  /// هل اللغة عربية؟
  bool get isArabic => language.value == AppConstants.languageArabic;

  /// هل الثيم داكن؟
  bool get isDarkMode => themeMode.value == 'dark';

  /// إعادة تعيين الإعدادات للقيم الافتراضية
  Future<void> resetToDefaults() async {
    language.value = AppConstants.languageArabic;
    themeMode.value = 'light';
    notificationsEnabled.value = true;
    soundEnabled.value = true;
    
    _applyLanguage();
    _applyTheme();
    await saveSettings();
  }
}
