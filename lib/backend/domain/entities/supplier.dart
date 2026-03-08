import 'package:meta/meta.dart';

/// Supplier domain entity
@immutable
class Supplier {
  const Supplier({
    required this.name, this.id,
    this.phone,
    this.address,
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
  final String? notes;
  final bool isActive;
  final double balance; // Amount we owe to supplier
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Check if supplier is deleted
  bool get isDeleted => deletedAt != null;

  /// Check if we owe money to supplier
  bool get hasOutstandingBalance => balance > 0;

  /// Copy with
  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    bool? isActive,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'Supplier(id: $id, name: $name, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
