import 'package:meta/meta.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/entities/user.dart';

/// Payment entity (Receipt or Payment)
@immutable
class Payment {
  const Payment({
    required this.paymentNumber, required this.type, required this.amount, required this.method, required this.paymentDate, this.id,
    this.customerId,
    this.customer,
    this.supplierId,
    this.supplier,
    this.invoiceId,
    this.purchaseInvoiceId,
    this.referenceNumber,
    this.notes,
    this.createdBy,
    this.createdByUser,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String paymentNumber;
  final String type; // 'receipt' or 'payment'
  final int? customerId;
  final Customer? customer;
  final int? supplierId;
  final Supplier? supplier;
  final int? invoiceId;
  final int? purchaseInvoiceId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final int? createdBy;
  final User? createdByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Check if this is a receipt (from customer)
  bool get isReceipt => type == 'receipt';

  /// Check if this is a payment (to supplier)
  bool get isPayment => type == 'payment';

  /// Check if payment is deleted
  bool get isDeleted => deletedAt != null;

  /// Get payment method display name
  String get methodDisplayName => method.nameAr;

  /// Get payment type display name
  String get typeDisplayName => isReceipt ? 'سند قبض' : 'سند صرف';

  /// Get party name (customer or supplier)
  String? get partyName => customer?.name ?? supplier?.name;

  /// Copy with
  Payment copyWith({
    int? id,
    String? paymentNumber,
    String? type,
    int? customerId,
    Customer? customer,
    int? supplierId,
    Supplier? supplier,
    double? amount,
    PaymentMethod? method,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    int? createdBy,
    User? createdByUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      supplierId: supplierId ?? this.supplierId,
      supplier: supplier ?? this.supplier,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdByUser: createdByUser ?? this.createdByUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Payment($paymentNumber: $partyName - $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
