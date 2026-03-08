import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class CashTransaction extends Equatable {

  const CashTransaction({
    required this.amount, required this.type, required this.description, required this.transactionDate, required this.createdBy, this.id,
    this.relatedPaymentId,
    this.relatedExpenseId,
    this.createdAt,
  });
  final int? id;
  final double amount;
  final String type; // 'in' or 'out'
  final String description;
  final DateTime transactionDate;
  final int? relatedPaymentId;
  final int? relatedExpenseId;
  final int createdBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        description,
        transactionDate,
        relatedPaymentId,
        relatedExpenseId,
        createdBy,
        createdAt,
      ];

  CashTransaction copyWith({
    int? id,
    double? amount,
    String? type,
    String? description,
    DateTime? transactionDate,
    int? relatedPaymentId,
    int? relatedExpenseId,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return CashTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      relatedPaymentId: relatedPaymentId ?? this.relatedPaymentId,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
