import 'package:meta/meta.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/user.dart';

/// Invoice Item entity
@immutable
class InvoiceItem {
  const InvoiceItem({
    required this.productId, required this.productName, required this.quantity, required this.unitPrice, required this.costAtSale, this.id,
    this.discount = 0.0,
  });

  final int? id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double costAtSale; // CRITICAL for profit calculation
  final double discount;

  /// Calculate subtotal (before discount)
  double get subtotal => quantity * unitPrice;

  /// Calculate total (after discount)
  double get total => subtotal - discount;

  /// Calculate profit for this item
  double get profit => total - (quantity * costAtSale);

  /// Calculate profit margin percentage
  double get profitMargin => total > 0 ? (profit / total) * 100 : 0;

  /// Copy with
  InvoiceItem copyWith({
    int? id,
    int? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? costAtSale,
    double? discount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costAtSale: costAtSale ?? this.costAtSale,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() => 'InvoiceItem($productName: $quantity x $unitPrice = $total)';
}

/// Sales Invoice entity
@immutable
class Invoice {
  const Invoice({
    required this.invoiceNumber, required this.customerId, required this.invoiceDate, required this.status, required this.items, this.id,
    this.customer,
    this.discount = 0.0,
    this.tax = 0.0,
    this.paidAmount = 0.0,
    this.notes,
    this.createdBy,
    this.createdByUser,
    this.confirmedAt,
    this.confirmedBy,
    this.confirmedByUser,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String invoiceNumber;
  final int customerId;
  final Customer? customer;
  final DateTime invoiceDate;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final double discount;
  final double tax;
  final double paidAmount;
  final String? notes;
  final int? createdBy;
  final User? createdByUser;
  final DateTime? confirmedAt;
  final int? confirmedBy;
  final User? confirmedByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Calculate subtotal (sum of all items)
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  /// Calculate total (subtotal - discount + tax)
  double get total => subtotal - discount + tax;

  /// Calculate remaining balance
  double get remainingBalance => total - paidAmount;

  /// Calculate total cost (for profit calculation)
  double get totalCost => items.fold(0, (sum, item) => sum + (item.quantity * item.costAtSale));

  /// Calculate total profit
  double get totalProfit => subtotal - totalCost - discount;

  /// Calculate profit margin percentage
  double get profitMargin => total > 0 ? (totalProfit / total) * 100 : 0;

  /// Check if invoice is fully paid
  bool get isFullyPaid => remainingBalance <= 0.001; // Use small epsilon for float comparison

  /// Check if invoice is partially paid
  bool get isPartiallyPaid => paidAmount > 0 && !isFullyPaid;

  /// Check if invoice is draft
  bool get isDraft => status == InvoiceStatus.draft;

  /// Check if invoice is confirmed
  bool get isConfirmed => status == InvoiceStatus.confirmed;

  /// Check if invoice is cancelled
  bool get isCancelled => status == InvoiceStatus.cancelled;

  /// Check if invoice is deleted
  bool get isDeleted => deletedAt != null;

  /// Check if invoice can be edited
  bool get canBeEdited => isDraft && !isDeleted;

  /// Check if invoice can be confirmed
  bool get canBeConfirmed => isDraft && items.isNotEmpty;

  /// Check if invoice can be cancelled
  bool get canBeCancelled => isConfirmed && !isDeleted;

  /// Get status display name
  String get statusDisplayName => status.nameAr;

  /// Days since invoice date
  int get daysSinceInvoice {
    final now = DateTime.now();
    return now.difference(invoiceDate).inDays;
  }

  /// Copy with
  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    Customer? customer,
    DateTime? invoiceDate,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    double? discount,
    double? tax,
    double? paidAmount,
    String? notes,
    int? createdBy,
    User? createdByUser,
    DateTime? confirmedAt,
    int? confirmedBy,
    User? confirmedByUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      status: status ?? this.status,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdByUser: createdByUser ?? this.createdByUser,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedByUser: confirmedByUser ?? this.confirmedByUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Invoice($invoiceNumber: ${customer?.name} - $total)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
