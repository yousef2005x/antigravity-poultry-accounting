import 'package:equatable/equatable.dart';

class AnnualInventory extends Equatable {
  const AnnualInventory({
    required this.amount,
    required this.inventoryDate,
    required this.description,
    this.id,
    this.createdBy,
  });

  final int? id;
  final double amount;
  final DateTime inventoryDate;
  final String description;
  final int? createdBy;

  @override
  List<Object?> get props => [
        id,
        amount,
        inventoryDate,
        description,
        createdBy,
      ];

  AnnualInventory copyWith({
    int? id,
    double? amount,
    DateTime? inventoryDate,
    String? description,
    int? createdBy,
  }) {
    return AnnualInventory(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      inventoryDate: inventoryDate ?? this.inventoryDate,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
