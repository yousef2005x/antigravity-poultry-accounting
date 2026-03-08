import 'package:meta/meta.dart';

/// Credit Note domain entity
@immutable
class CreditNote {
  const CreditNote({
    this.id,
    required this.creditNoteNumber,
    required this.creditNoteDate,
    this.docstatus = 0,
    required this.originalInvoiceType,
    required this.originalInvoiceId,
    required this.amount,
    this.reason,
    this.branchId,
    this.submittedAt,
    this.submittedById,
    this.createdById,
    this.createdAt,
  });

  final int? id;
  final String creditNoteNumber;
  final DateTime creditNoteDate;
  final int docstatus; // 0=draft, 1=submitted
  final String originalInvoiceType; // sale, purchase
  final int originalInvoiceId;
  final double amount;
  final String? reason;
  final int? branchId;
  final DateTime? submittedAt;
  final int? submittedById;
  final int? createdById;
  final DateTime? createdAt;

  bool get isDraft => docstatus == 0;
  bool get isSubmitted => docstatus == 1;

  CreditNote copyWith({
    int? id,
    String? creditNoteNumber,
    DateTime? creditNoteDate,
    int? docstatus,
    String? originalInvoiceType,
    int? originalInvoiceId,
    double? amount,
    String? reason,
    int? branchId,
    DateTime? submittedAt,
    int? submittedById,
    int? createdById,
    DateTime? createdAt,
  }) {
    return CreditNote(
      id: id ?? this.id,
      creditNoteNumber: creditNoteNumber ?? this.creditNoteNumber,
      creditNoteDate: creditNoteDate ?? this.creditNoteDate,
      docstatus: docstatus ?? this.docstatus,
      originalInvoiceType: originalInvoiceType ?? this.originalInvoiceType,
      originalInvoiceId: originalInvoiceId ?? this.originalInvoiceId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      branchId: branchId ?? this.branchId,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedById: submittedById ?? this.submittedById,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'CreditNote(id: $id, number: $creditNoteNumber, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditNote && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
