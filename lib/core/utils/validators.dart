/// مجموعة دوال التحقق من صحة البيانات
class Validators {
  /// التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    
    return null;
  }

  /// التحقق من صحة رقم الهاتف
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختياري
    }
    
    // التحقق من صيغة رقم الهاتف السعودي
    final phoneRegex = RegExp(r'^05\d{8}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'صيغة رقم الهاتف غير صحيحة (05xxxxxxxx)';
    }
    
    return null;
  }

  /// التحقق من صحة اسم الحساب
  static String? validateAccountName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم الحساب';
    }
    
    if (value.length < 2) {
      return 'اسم الحساب يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 100) {
      return 'اسم الحساب طويل جداً';
    }
    
    return null;
  }

  /// التحقق من صحة المبلغ
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال المبلغ';
    }
    
    final amount = double.tryParse(value);
    
    if (amount == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    
    if (amount <= 0) {
      return 'المبلغ يجب أن يكون أكبر من صفر';
    }
    
    if (amount > 999999999) {
      return 'المبلغ كبير جداً';
    }
    
    return null;
  }

  /// التحقق من صحة اسم المستخدم
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال اسم المستخدم';
    }
    
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    
    if (value.length > 50) {
      return 'اسم المستخدم طويل جداً';
    }
    
    return null;
  }

  /// التحقق من صحة الوصف
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الوصف';
    }
    
    if (value.length < 2) {
      return 'الوصف يجب أن يكون حرفين على الأقل';
    }
    
    if (value.length > 500) {
      return 'الوصف طويل جداً';
    }
    
    return null;
  }

  /// التحقق من صحة الملاحظات (اختياري)
  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // اختياري
    }
    
    if (value.length > 1000) {
      return 'الملاحظات طويلة جداً';
    }
    
    return null;
  }

  /// التحقق من حقل مطلوب عام
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null 
          ? 'يرجى إدخال $fieldName' 
          : 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// التحقق من الحد الأدنى للطول
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length < minLength) {
      return fieldName != null
          ? '$fieldName يجب أن يكون $minLength أحرف على الأقل'
          : 'يجب أن يكون $minLength أحرف على الأقل';
    }
    
    return null;
  }

  /// التحقق من الحد الأقصى للطول
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > maxLength) {
      return fieldName != null
          ? '$fieldName طويل جداً (الحد الأقصى $maxLength)'
          : 'النص طويل جداً (الحد الأقصى $maxLength)';
    }
    
    return null;
  }
}
