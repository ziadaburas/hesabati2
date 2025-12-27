import 'package:intl/intl.dart';
import '/core/constants/app_constants.dart';

/// دوال تنسيق العملة
class CurrencyFormatter {
  /// تنسيق المبلغ كعملة
  static String formatCurrency(double amount, {String? currency}) {
    final formatter = NumberFormat.currency(
      symbol: currency ?? AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// تنسيق المبلغ بدون رمز العملة
  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  /// تنسيق المبلغ مع العملة بشكل مختصر
  static String formatShort(double amount, {String? currency}) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ${currency ?? AppConstants.currencySymbol}';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ${currency ?? AppConstants.currencySymbol}';
    } else {
      return '${amount.toStringAsFixed(2)} ${currency ?? AppConstants.currencySymbol}';
    }
  }

  /// تحليل المبلغ من نص
  static double? parseCurrency(String value) {
    // إزالة الفواصل والأحرف غير الرقمية
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanValue);
  }

  /// تنسيق المبلغ مع إشارة
  static String formatWithSign(double amount, {String? currency}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${formatCurrency(amount, currency: currency)}';
  }

  /// الحصول على لون المبلغ (أخضر للموجب، أحمر للسالب)
  static bool isPositive(double amount) => amount >= 0;

  /// تنسيق المبلغ للعرض في القوائم
  static String formatForList(double amount) {
    return '${amount.toStringAsFixed(2)} ${AppConstants.currencySymbol}';
  }

  /// تحويل من نص إلى رقم مع معالجة الأخطاء
  static double parseOrZero(String value) {
    return parseCurrency(value) ?? 0.0;
  }
}
