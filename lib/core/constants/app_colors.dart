import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5); // أزرق
  static const Color secondary = Color(0xFF43A047); // أخضر
  
  // Status Colors
  static const Color error = Color(0xFFE53935); // أحمر
  static const Color success = Color(0xFF4CAF50); // أخضر فاتح
  static const Color warning = Color(0xFFFFA726); // برتقالي
  static const Color info = Color(0xFF29B6F6); // أزرق فاتح
  
  // Account Types Colors
  static const Color loan = Color(0xFF2196F3); // دين (أزرق)
  static const Color debt = Color(0xFFFF5722); // مديونية (برتقالي محمر)
  static const Color savings = Color(0xFF4CAF50); // توفير (أخضر)
  static const Color shared = Color(0xFF9C27B0); // مشترك (بنفسجي)
  
  // Status Colors for Accounts/Transactions
  static const Color pending = Color(0xFFFFA726); // معلق
  static const Color active = Color(0xFF4CAF50); // نشط
  static const Color rejected = Color(0xFFE53935); // مرفوض
  static const Color completed = Color(0xFF66BB6A); // مكتمل
  static const Color closed = Color(0xFF757575); // مغلق
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
