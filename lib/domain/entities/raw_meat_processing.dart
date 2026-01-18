import 'package:equatable/equatable.dart';

class RawMeatProcessing extends Equatable {

  const RawMeatProcessing({
    required this.batchNumber, required this.grossWeight, required this.basketWeight, required this.basketCount, required this.netWeight, 
    required this.totalCost, // Added totalCost
    required this.processingDate, required this.createdBy, this.id,
    this.supplierId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });
  final int? id;
  final String batchNumber;
  final double grossWeight;
  final double basketWeight;
  final int basketCount;
  final double netWeight;
  final double totalCost; // Total cost of the raw meat batch
  final int? supplierId;
  final DateTime processingDate;
  final String? notes;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        batchNumber,
        grossWeight,
        basketWeight,
        basketCount,
        netWeight,
        totalCost,
        supplierId,
        processingDate,
        notes,
        createdBy,
        createdAt,
        updatedAt,
      ];

  RawMeatProcessing copyWith({
    int? id,
    String? batchNumber,
    double? grossWeight,
    double? basketWeight,
    int? basketCount,
    double? netWeight,
    double? totalCost,
    int? supplierId,
    DateTime? processingDate,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMeatProcessing(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      grossWeight: grossWeight ?? this.grossWeight,
      basketWeight: basketWeight ?? this.basketWeight,
      basketCount: basketCount ?? this.basketCount,
      netWeight: netWeight ?? this.netWeight,
      totalCost: totalCost ?? this.totalCost,
      supplierId: supplierId ?? this.supplierId,
      processingDate: processingDate ?? this.processingDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
