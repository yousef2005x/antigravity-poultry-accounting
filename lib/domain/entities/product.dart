import 'package:meta/meta.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';

/// Product domain entity
@immutable
class Product {
  const Product({
    required this.name, required this.unitType, this.id,
    this.isWeighted = true,
    this.defaultPrice = 0.0,
    this.description,
    this.isActive = true,
    this.currentStock = 0.0,
    this.averageCost = 0.0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String name;
  final UnitType unitType;
  final bool isWeighted;
  final double defaultPrice;
  final String? description;
  final bool isActive;
  final double currentStock; // Calculated field
  final double averageCost; // Calculated field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Check if product is deleted
  bool get isDeleted => deletedAt != null;

  /// Check if product is in stock
  bool get isInStock => currentStock > 0;

  /// Check if product is out of stock
  bool get isOutOfStock => currentStock <= 0;

  /// Get unit display name
  String get unitDisplayName => unitType.nameAr;

  /// Copy with
  Product copyWith({
    int? id,
    String? name,
    UnitType? unitType,
    bool? isWeighted,
    double? defaultPrice,
    String? description,
    bool? isActive,
    double? currentStock,
    double? averageCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      isWeighted: isWeighted ?? this.isWeighted,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      currentStock: currentStock ?? this.currentStock,
      averageCost: averageCost ?? this.averageCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, stock: $currentStock)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
