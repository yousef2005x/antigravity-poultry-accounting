import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Security utility functions
class SecurityUtils {
  SecurityUtils._();

  /// Hash password using SHA-256
  static String hashPassword(String password, {String? salt}) {
    final saltedPassword = salt != null ? '$password$salt' : password;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random salt
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return hashPassword(random);
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash, {String? salt}) {
    final hashedPassword = hashPassword(password, salt: salt);
    return hashedPassword == hash;
  }

  /// Generate simple token (for sessions)
  static String generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode + DateTime.now().microsecond).toString();
    return hashPassword(random);
  }

  /// Sanitize string input (remove dangerous characters)
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('&', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('/', '')
        .replaceAll(r'\', '');
  }

  /// Mask sensitive data (e.g., show last 4 digits of phone)
  static String maskPhone(String phone) {
    if (phone.length <= 4) {
      return phone;
    }
    final visible = phone.substring(phone.length - 4);
    final masked = '*' * (phone.length - 4);
    return masked + visible;
  }

  /// Mask email (show first char and domain)
  static String maskEmail(String email) {
    if (!email.contains('@')) {
      return email;
    }
    
    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.isEmpty) {
      return email;
    }
    
    final visibleChar = username[0];
    final masked = visibleChar + ('*' * (username.length - 1));
    
    return '$masked@$domain';
  }
}
