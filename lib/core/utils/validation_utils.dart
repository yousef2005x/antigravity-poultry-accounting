/// Validation utility class
class ValidationUtils {
  ValidationUtils._();

  /// Validate email (basic)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhone(String phone) {
    // Remove spaces, dashes, and other formatting
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's all digits and reasonable length
    return RegExp(r'^\d{7,15}$').hasMatch(cleaned);
  }

  /// Validate not empty
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate min length
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  /// Validate max length
  static bool hasMaxLength(String? value, int maxLength) {
    return value == null || value.length <= maxLength;
  }

  /// Validate positive number
  static bool isPositive(double? value) {
    return value != null && value > 0;
  }

  /// Validate non-negative number
  static bool isNonNegative(double? value) {
    return value != null && value >= 0;
  }

  /// Validate number range
  static bool isInRange(double? value, double min, double max) {
    return value != null && value >= min && value <= max;
  }

  /// Validate username
  static bool isValidUsername(String username) {
    // Alphanumeric and underscore only, 3-20 chars
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 chars, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        RegExp('[A-Z]').hasMatch(password) &&
        RegExp('[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }

  /// Get password strength level (0-4)
  static int getPasswordStrength(String password) {
    var strength = 0;
    
    if (password.length >= 6) {
      strength++;
    }
    if (password.length >= 10) {
      strength++;
    }
    if (RegExp('[A-Z]').hasMatch(password)) {
      strength++;
    }
    if (RegExp('[a-z]').hasMatch(password)) {
      strength++;
    }
    if (RegExp(r'\d').hasMatch(password)) {
      strength++;
    }
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    }
    
    return (strength / 1.5).round().clamp(0, 4);
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'ضعيفة جداً';
      case 2:
        return 'ضعيفة';
      case 3:
        return 'متوسطة';
      case 4:
        return 'قوية';
      default:
        return '';
    }
  }
}

/// Form field validators
class FormValidators {
  FormValidators._();

  /// Required field validator
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'هذا الحقل'} مطلوب';
    }
    return null;
  }

  /// Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!ValidationUtils.isValidEmail(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  /// Phone validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!ValidationUtils.isValidPhone(value)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  /// Min length validator
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!ValidationUtils.hasMinLength(value, minLength)) {
      return '${fieldName ?? 'هذا الحقل'} يجب أن يكون $minLength أحرف على الأقل';
    }
    return null;
  }

  /// Max length validator
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!ValidationUtils.hasMaxLength(value, maxLength)) {
      return '${fieldName ?? 'هذا الحقل'} يجب أن لا يتجاوز $maxLength حرف';
    }
    return null;
  }

  /// Positive number validator
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'يجب إدخال رقم صحيح';
    }
    
    if (!ValidationUtils.isPositive(number)) {
      return '${fieldName ?? 'الرقم'} يجب أن يكون أكبر من صفر';
    }
    return null;
  }

  /// Non-negative number validator
  static String? nonNegativeNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'يجب إدخال رقم صحيح';
    }
    
    if (!ValidationUtils.isNonNegative(number)) {
      return '${fieldName ?? 'الرقم'} لا يمكن أن يكون سالب';
    }
    return null;
  }

  /// Username validator
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    
    if (!ValidationUtils.isValidUsername(value)) {
      return 'اسم المستخدم يجب أن يكون بين 3-20 حرف (أحرف إنجليزية وأرقام فقط)';
    }
    return null;
  }

  /// Password validator
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  /// Strong password validator
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (!ValidationUtils.isStrongPassword(value)) {
      return 'كلمة المرور ضعيفة. يجب أن تحتوي على 8 أحرف، حرف كبير، حرف صغير، ورقم';
    }
    return null;
  }

  /// Confirm password validator
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    
    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  /// Combine multiple validators
  static String? combine(List<String? Function(String?)> validators, String? value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
