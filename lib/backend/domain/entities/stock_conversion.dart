import 'package:equatable/equatable.dart';

class StockConversion extends Equatable {
  const StockConversion({
    required this.conversionDate,
    required this.sourceProductId,
    required this.sourceQuantity,
    required this.createdBy,
    this.id,
    this.batchNumber,
    this.notes,
    this.createdAt,
  });

  final int? id;
  final DateTime conversionDate;
  final int sourceProductId;
  final double sourceQuantity;
  final String? batchNumber;
  final String? notes;
  final int createdBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        conversionDate,
        sourceProductId,
        sourceQuantity,
        batchNumber,
        notes,
        createdBy,
        createdAt,
      ];
}

class StockConversionItem extends Equatable {
  const StockConversionItem({
    required this.conversionId,
    required this.productId,
    required this.quantity,
    required this.yieldPercentage,
    required this.unitCost,
    this.id,
  });

  final int? id;
  final int conversionId;
  final int productId;
  final double quantity;
  final double yieldPercentage;
  final double unitCost;

  @override
  List<Object?> get props => [
        id,
        conversionId,
        productId,
        quantity,
        yieldPercentage,
        unitCost,
      ];
}
