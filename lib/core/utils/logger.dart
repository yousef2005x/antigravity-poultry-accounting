import 'package:logger/logger.dart';

/// Application logger
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug log
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info log
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning log
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error log
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal error log
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log database operation
  static void database(String operation, {Map<String, dynamic>? params}) {
    debug('DB Operation: $operation${params != null ? ' | Params: $params' : ''}');
  }

  /// Log business rule violation
  static void businessRule(String rule, String message) {
    warning('Business Rule Violation: $rule | $message');
  }

  /// Log authentication event
  static void auth(String event, {String? username}) {
    info('Auth Event: $event${username != null ? ' | User: $username' : ''}');
  }

  /// Log navigation
  static void navigation(String from, String to) {
    debug('Navigation: $from → $to');
  }
}
