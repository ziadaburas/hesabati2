import 'package:intl/intl.dart';
import '/core/constants/app_constants.dart';

/// دوال تنسيق التاريخ والوقت
class DateFormatter {
  /// تنسيق التاريخ للعرض
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormatDisplay).format(date);
  }

  /// تنسيق التاريخ والوقت للعرض
  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormatDisplay).format(date);
  }

  /// تنسيق التاريخ لقاعدة البيانات
  static String formatForDatabase(DateTime date) {
    return DateFormat(AppConstants.dateFormatDatabase).format(date);
  }

  /// تحليل التاريخ من نص
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على التاريخ النسبي (مثل: منذ 5 دقائق)
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  /// هل التاريخ اليوم؟
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// هل التاريخ بالأمس؟
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// الحصول على اسم اليوم بالعربي
  static String getDayName(DateTime date) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[date.weekday - 1];
  }

  /// الحصول على اسم الشهر بالعربي
  static String getMonthName(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[date.month - 1];
  }

  /// تنسيق التاريخ بشكل ودي
  static String formatFriendly(DateTime date) {
    if (isToday(date)) {
      return 'اليوم ${DateFormat('HH:mm').format(date)}';
    } else if (isYesterday(date)) {
      return 'أمس ${DateFormat('HH:mm').format(date)}';
    } else {
      return formatDateTime(date);
    }
  }
}
