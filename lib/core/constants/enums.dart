// Enums for the Poultry Accounting System
// NOTE: UserRole, InvoiceStatus, PaymentMethod, and UnitType are defined in app_constants.dart

/// Payment types (incoming/outgoing)
enum PaymentType {
  receipt, // incoming (قبض)
  payment, // outgoing (صرف)
}

/// Transaction types
enum TransactionType {
  income,
  expense,
  transfer,
}

/// Partner transaction types
enum PartnerTransactionType {
  drawing, // سحب شريك
  distribution, // توزيع أرباح
  contribution, // إضافة رأس مال
}

/// Processing status
enum ProcessingStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

/// Backup status
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Product types
enum ProductType {
  rawMeat, // لحم طازج
  processed, // معالج
  byProduct, // منتج ثانوي
}

// Extension methods for PaymentType
extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.receipt:
        return 'قبض';
      case PaymentType.payment:
        return 'صرف';
    }
  }

  String get name {
    switch (this) {
      case PaymentType.receipt:
        return 'receipt';
      case PaymentType.payment:
        return 'payment';
    }
  }
}
