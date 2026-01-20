import 'package:equatable/equatable.dart';

class RawMeatProcessing extends Equatable {

  const RawMeatProcessing({
    required this.batchNumber,
    required this.liveGrossWeight,
    required this.liveCrateWeight,
    required this.liveCrateCount,
    required this.liveNetWeight,
    required this.slaughteredGrossWeight,
    required this.slaughteredBasketWeight,
    required this.slaughteredBasketCount,
    required this.slaughteredNetWeight,
    required this.netWeight, // Legacy/Summary Net Weight
    required this.totalCost,
    required this.processingDate,
    required this.createdBy,
    this.id,
    this.supplierId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String batchNumber;
  
  // Stage 1: Live
  final double liveGrossWeight;
  final double liveCrateWeight;
  final int liveCrateCount;
  final double liveNetWeight;
  
  // Stage 2: Slaughtered
  final double slaughteredGrossWeight;
  final double slaughteredBasketWeight;
  final int slaughteredBasketCount;
  final double slaughteredNetWeight;

  final double netWeight; // Overall net weight (usually same as slaughteredNetWeight)
  final double totalCost;
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
        liveGrossWeight,
        liveCrateWeight,
        liveCrateCount,
        liveNetWeight,
        slaughteredGrossWeight,
        slaughteredBasketWeight,
        slaughteredBasketCount,
        slaughteredNetWeight,
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
    double? liveGrossWeight,
    double? liveCrateWeight,
    int? liveCrateCount,
    double? liveNetWeight,
    double? slaughteredGrossWeight,
    double? slaughteredBasketWeight,
    int? slaughteredBasketCount,
    double? slaughteredNetWeight,
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
      liveGrossWeight: liveGrossWeight ?? this.liveGrossWeight,
      liveCrateWeight: liveCrateWeight ?? this.liveCrateWeight,
      liveCrateCount: liveCrateCount ?? this.liveCrateCount,
      liveNetWeight: liveNetWeight ?? this.liveNetWeight,
      slaughteredGrossWeight: slaughteredGrossWeight ?? this.slaughteredGrossWeight,
      slaughteredBasketWeight: slaughteredBasketWeight ?? this.slaughteredBasketWeight,
      slaughteredBasketCount: slaughteredBasketCount ?? this.slaughteredBasketCount,
      slaughteredNetWeight: slaughteredNetWeight ?? this.slaughteredNetWeight,
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
