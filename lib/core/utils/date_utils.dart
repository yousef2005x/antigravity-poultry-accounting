import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';

/// Utility class for date operations
class AppDateUtils {
  AppDateUtils._();

  /// Format date to display format (dd/MM/yyyy)
  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Format date time to display format (dd/MM/yyyy HH:mm)
  static String formatDisplayDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.displayDateTimeFormat).format(dateTime);
  }

  /// Format date for database storage (yyyy-MM-dd)
  static String formatDatabaseDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format date time for database storage (yyyy-MM-dd HH:mm:ss)
  static String formatDatabaseDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Parse date from string
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is in current year
  static bool isCurrentYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return (toDate.difference(fromDate).inHours / 24).round();
  }

  /// Calculate aging category (0-30, 31-60, 61-90, 90+)
  static String getAgingCategory(DateTime invoiceDate) {
    final days = daysBetween(invoiceDate, DateTime.now());
    
    if (days <= 30) {
      return '0-30 يوم';
    } else if (days <= 60) {
      return '31-60 يوم';
    } else if (days <= 90) {
      return '61-90 يوم';
    } else {
      return 'أكثر من 90 يوم';
    }
  }

  /// Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(targetDate).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference == -1) {
      return 'غداً';
    } else if (difference > 0 && difference <= 7) {
      return 'منذ $difference أيام';
    } else if (difference < 0 && difference >= -7) {
      return 'بعد ${-difference} أيام';
    } else {
      return formatDisplayDate(date);
    }
  }
}
