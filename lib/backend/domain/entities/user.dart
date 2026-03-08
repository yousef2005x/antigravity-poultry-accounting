import 'package:meta/meta.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';

/// User domain entity
@immutable
class User {
  const User({
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.id,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Check if user is deleted
  bool get isDeleted => deletedAt != null;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is accountant
  bool get isAccountant => role == UserRole.accountant;

  /// Check if user can manage users
  bool get canManageUsers => isAdmin;

  /// Check if user can delete invoices
  bool get canDeleteInvoices => isAdmin || isAccountant;

  /// Check if user can edit prices
  bool get canEditPrices => isAdmin || isAccountant;

  /// Check if user can view reports
  bool get canViewReports => role != UserRole.viewer;

  /// Get role display name
  String get roleDisplayName => role.nameAr;

  /// Copy with
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'User(id: $id, username: $username, role: ${role.nameAr})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
