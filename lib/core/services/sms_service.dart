import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service to handle SMS/OTP verification
class SmsService {
  String? _lastGeneratedCode;
  String? _lastPhoneNumber;

  /// Send verification code to phone number
  Future<bool> sendVerificationCode(String phoneNumber) async {
    // Mock sending SMS
    _lastPhoneNumber = phoneNumber;
    _lastGeneratedCode = _generateCode();
    
    if (kDebugMode) {
      print('==========================================');
      print('SMS SERVICE (MOCK): Sending code to $phoneNumber');
      print('CODE: $_lastGeneratedCode');
      print('==========================================');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// Verify the code entered by user
  bool verifyCode(String phoneNumber, String code) {
    if (_lastPhoneNumber == phoneNumber && _lastGeneratedCode == code) {
      // Clear after successful verification
      _lastGeneratedCode = null;
      _lastPhoneNumber = null;
      return true;
    }
    return false;
  }

  String _generateCode() {
    final random = Random();
    final code = 1000 + random.nextInt(9000); // 4 digit code
    return code.toString();
  }
}
