/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Poultry Accounting';
  static const String appVersion = '1.0.0';
  static const String appOrganization = 'Poultry Distribution';

  // Database
  static const String databaseName = 'poultry_accounting.db';
  static const int databaseVersion = 1;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxCustomerNameLength = 100;
  static const int maxPhoneLength = 20;
  static const int maxNotesLength = 500;

  // Business Rules
  static const double defaultCreditLimit = 10000;
  static const int paymentDueDays = 30;
  static const int agingPeriodDays = 30; // 0-30, 31-60, 61-90, 90+

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String currencySymbol = '₪'; // Shekel
  static const String currencyCode = 'ILS';
  static const int currencyDecimals = 2;

  // Weight Units
  static const String weightUnitKg = 'كغ';
  static const String weightUnitGram = 'غرام';
  static const String unitPiece = 'قطعة';
  static const String unitBox = 'صندوق';

  // Backup
  static const String backupFileExtension = '.backup';
  static const String backupDateFormat = 'yyyyMMdd_HHmmss';
  static const int maxBackupRetention = 30; // days

  // Default Values
  static const String defaultAdminUsername = 'admin';
  static const String defaultAdminPassword = 'admin123'; // Change in production!
}

/// User Roles
enum UserRole {
  admin('admin', 'مدير النظام'),
  accountant('accountant', 'محاسب'),
  sales('sales', 'مبيعات'),
  viewer('viewer', 'مشاهد');

  const UserRole(this.code, this.nameAr);

  final String code;
  final String nameAr;

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.viewer,
    );
  }
}

/// Invoice Status
enum InvoiceStatus {
  draft('draft', 'مسودة'),
  confirmed('confirmed', 'مؤكدة'),
  cancelled('cancelled', 'ملغاة');

  const InvoiceStatus(this.code, this.nameAr);

  final String code;
  final String nameAr;

  static InvoiceStatus fromCode(String code) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

/// Payment Method
enum PaymentMethod {
  cash('cash', 'نقدي'),
  bankTransfer('bank_transfer', 'تحويل بنكي'),
  check('check', 'شيك'),
  credit('credit', 'آجل');

  const PaymentMethod(this.code, this.nameAr);

  final String code;
  final String nameAr;

  static PaymentMethod fromCode(String code) {
    return PaymentMethod.values.firstWhere(
      (method) => method.code == code,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Unit Type
enum UnitType {
  kilogram('kg', 'كيلو'),
  gram('gram', 'غرام'),
  piece('piece', 'قطعة'),
  box('box', 'صندوق');

  const UnitType(this.code, this.nameAr);

  final String code;
  final String nameAr;

  static UnitType fromCode(String code) {
    return UnitType.values.firstWhere(
      (unit) => unit.code == code,
      orElse: () => UnitType.kilogram,
    );
  }
}

/// Audit Action Types
enum AuditAction {
  create('create', 'إنشاء'),
  update('update', 'تعديل'),
  delete('delete', 'حذف'),
  confirm('confirm', 'تأكيد'),
  cancel('cancel', 'إلغاء');

  const AuditAction(this.code, this.nameAr);

  final String code;
  final String nameAr;
}
