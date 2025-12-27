import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/localization/strings/ar.dart';
import '/core/localization/strings/en.dart';

/// خدمة الترجمة والتوطين
class LocalizationService extends Translations {
  // اللغة الافتراضية
  static const Locale defaultLocale = Locale('ar', 'EG');
  
  // اللغات المدعومة
  static const List<Locale> supportedLocales = [
    Locale('ar', 'EG'),
    Locale('en', 'US'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
    'ar_EG': arStrings,
    'en_US': enStrings,
  };

  /// تغيير اللغة
  static void changeLocale(String languageCode) {
    final locale = _getLocaleFromCode(languageCode);
    Get.updateLocale(locale);
  }

  /// الحصول على Locale من كود اللغة
  static Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'ar':
        return const Locale('ar', 'EG');
      case 'en':
        return const Locale('en', 'US');
      default:
        return defaultLocale;
    }
  }

  /// هل اللغة الحالية عربية؟
  static bool get isArabic => Get.locale?.languageCode == 'ar';

  /// هل اللغة الحالية من اليمين لليسار؟
  static bool get isRTL => isArabic;
}
