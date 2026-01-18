import 'package:meta/meta.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/entities/user.dart';

@immutable
class PurchaseInvoiceItem {
  const PurchaseInvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.id,
    this.total,
  });

  final int? id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double? total;

  double get calculatedTotal => quantity * unitCost;

  PurchaseInvoiceItem copyWith({
    int? id,
    int? productId,
    String? productName,
    double? quantity,
    double? unitCost,
    double? total,
  }) {
    return PurchaseInvoiceItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      total: total ?? this.total,
    );
  }
}

@immutable
class PurchaseInvoice {
  const PurchaseInvoice({
    required this.invoiceNumber,
    required this.supplierId,
    required this.invoiceDate,
    required this.status,
    required this.items,
    this.id,
    this.supplier,
    this.discount = 0.0,
    this.tax = 0.0,
    this.paidAmount = 0.0,
    this.additionalCosts = 0.0,
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
  final int supplierId;
  final Supplier? supplier;
  final DateTime invoiceDate;
  final InvoiceStatus status;
  final List<PurchaseInvoiceItem> items;
  final double discount;
  final double tax;
  final double paidAmount;
  final double additionalCosts;
  final String? notes;
  final int? createdBy;
  final User? createdByUser;
  final DateTime? confirmedAt;
  final int? confirmedBy;
  final User? confirmedByUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  double get subtotal => items.fold(0, (sum, item) => sum + item.calculatedTotal);
  double get total => subtotal - discount + tax + additionalCosts;
  double get remainingBalance => total - paidAmount;

  /// Get status display name
  String get statusDisplayName => status.nameAr;

  PurchaseInvoice copyWith({
    int? id,
    String? invoiceNumber,
    int? supplierId,
    Supplier? supplier,
    DateTime? invoiceDate,
    InvoiceStatus? status,
    List<PurchaseInvoiceItem>? items,
    double? discount,
    double? tax,
    double? paidAmount,
    double? additionalCosts,
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
    return PurchaseInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplier: supplier ?? this.supplier,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      status: status ?? this.status,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      paidAmount: paidAmount ?? this.paidAmount,
      additionalCosts: additionalCosts ?? this.additionalCosts,
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
}
