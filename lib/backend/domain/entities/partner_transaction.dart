import 'package:equatable/equatable.dart';

class PartnerTransaction extends Equatable {

  const PartnerTransaction({
    required this.partnerId, required this.amount, required this.type, required this.transactionDate, required this.createdBy, this.id,
    this.notes,
    this.createdAt,
  });
  final int? id;
  final int partnerId;
  final double amount;
  final String type; // 'drawing' or 'distribution'
  final DateTime transactionDate;
  final String? notes;
  final int createdBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        partnerId,
        amount,
        type,
        transactionDate,
        notes,
        createdBy,
        createdAt,
      ];

  PartnerTransaction copyWith({
    int? id,
    int? partnerId,
    double? amount,
    String? type,
    DateTime? transactionDate,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return PartnerTransaction(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
