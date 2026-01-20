import 'package:equatable/equatable.dart';

class ProcessingOutput extends Equatable {

  const ProcessingOutput({
    required this.processingId,
    required this.productId,
    required this.grossWeight,
    required this.basketWeight,
    required this.basketCount,
    required this.quantity,
    required this.yieldPercentage,
    this.id,
    this.createdAt,
  });

  final int? id;
  final int processingId;
  final int productId;
  final double grossWeight;
  final double basketWeight;
  final int basketCount;
  final double quantity; // Net weight
  final double yieldPercentage;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        processingId,
        productId,
        grossWeight,
        basketWeight,
        basketCount,
        quantity,
        yieldPercentage,
        createdAt,
      ];

  ProcessingOutput copyWith({
    int? id,
    int? processingId,
    int? productId,
    double? grossWeight,
    double? basketWeight,
    int? basketCount,
    double? quantity,
    double? yieldPercentage,
    DateTime? createdAt,
  }) {
    return ProcessingOutput(
      id: id ?? this.id,
      processingId: processingId ?? this.processingId,
      productId: productId ?? this.productId,
      grossWeight: grossWeight ?? this.grossWeight,
      basketWeight: basketWeight ?? this.basketWeight,
      basketCount: basketCount ?? this.basketCount,
      quantity: quantity ?? this.quantity,
      yieldPercentage: yieldPercentage ?? this.yieldPercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
