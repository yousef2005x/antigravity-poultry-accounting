import 'package:equatable/equatable.dart';

class ProductPrice extends Equatable {

  const ProductPrice({
    required this.productId, required this.price, required this.date, this.id,
    this.createdAt,
  });
  final int? id;
  final int productId;
  final double price;
  final DateTime date;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, productId, price, date, createdAt];

  ProductPrice copyWith({
    int? id,
    int? productId,
    double? price,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return ProductPrice(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      price: price ?? this.price,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
