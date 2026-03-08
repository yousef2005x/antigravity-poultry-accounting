import 'package:meta/meta.dart';

/// Customer domain entity
@immutable
class Customer {
  const Customer({
    required this.name, this.id,
    this.phone,
    this.address,
    this.creditLimit = 10000.0,
    this.notes,
    this.isActive = true,
    this.balance = 0.0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final double creditLimit;
  final String? notes;
  final bool isActive;
  final double balance; // Calculated field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Check if customer is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Check if credit limit is exceeded
  bool get isCreditLimitExceeded => balance > creditLimit;

  /// Get available credit
  double get availableCredit => creditLimit - balance;

  /// Copy with
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? creditLimit,
    String? notes,
    bool? isActive,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
