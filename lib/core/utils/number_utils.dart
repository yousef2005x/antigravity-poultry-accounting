import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';

/// Utility class for number operations
class NumberUtils {
  NumberUtils._();

  /// Format currency (e.g., 1,234.56 ₪)
  static String formatCurrency(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'ar',
      symbol: includeSymbol ? AppConstants.currencySymbol : '',
      decimalDigits: AppConstants.currencyDecimals,
    );
    return formatter.format(amount);
  }

  /// Format weight (kg)
  static String formatWeight(double weight, {int decimals = 2}) {
    return '${weight.toStringAsFixed(decimals)} ${AppConstants.weightUnitKg}';
  }

  /// Format number with commas
  static String formatNumber(num number, {int decimals = 0}) {
    final formatter = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}', 'ar');
    return formatter.format(number);
  }

  /// Parse string to double
  static double? parseDouble(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    // Remove any non-numeric characters except . and -
    final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
    
    try {
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Parse string to int
  static int? parseInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    // Remove any non-numeric characters except -
    final cleaned = value.replaceAll(RegExp(r'[^\d-]'), '');
    
    try {
      return int.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Round to decimal places
  static double roundToDecimal(double value, int decimalPlaces) {
    final factor = 10.0 * decimalPlaces;
    return (value * factor).round() / factor;
  }

  /// Calculate percentage
  static double calculatePercentage(double part, double total) {
    if (total == 0) {
      return 0;
    }
    return (part / total) * 100;
  }

  /// Format percentage
  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Calculate profit margin
  static double calculateProfitMargin(double cost, double price) {
    if (price == 0) {
      return 0;
    }
    return ((price - cost) / price) * 100;
  }

  /// Calculate markup
  static double calculateMarkup(double cost, double price) {
    if (cost == 0) {
      return 0;
    }
    return ((price - cost) / cost) * 100;
  }

  /// Check if number is zero
  static bool isZero(double? value) {
    return value == null || value.abs() < 0.001;
  }

  /// Check if number is positive
  static bool isPositive(double? value) {
    return value != null && value > 0;
  }

  /// Check if number is negative
  static bool isNegative(double? value) {
    return value != null && value < 0;
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// Safe division (returns 0 if divisor is 0)
  static double safeDivide(double dividend, double divisor) {
    return divisor == 0 ? 0 : dividend / divisor;
  }

  /// Sum a list of numbers
  static double sum(List<double> numbers) {
    return numbers.fold(0, (sum, value) => sum + value);
  }

  /// Average of a list of numbers
  static double average(List<double> numbers) {
    if (numbers.isEmpty) {
      return 0;
    }
    return sum(numbers) / numbers.length;
  }

  /// Get min from list
  static double? min(List<double> numbers) {
    if (numbers.isEmpty) {
      return null;
    }
    return numbers.reduce((a, b) => a < b ? a : b);
  }

  /// Get max from list
  static double? max(List<double> numbers) {
    if (numbers.isEmpty) {
      return null;
    }
    return numbers.reduce((a, b) => a > b ? a : b);
  }
}
