import 'package:poultry_accounting/domain/entities/supplier.dart';

/// Supplier Repository Interface
abstract class SupplierRepository {
  /// Get all suppliers
  Future<List<Supplier>> getAllSuppliers();

  /// Watch all suppliers
  Stream<List<Supplier>> watchAllSuppliers();

  /// Get supplier by ID
  Future<Supplier?> getSupplierById(int id);

  /// Search suppliers by name or phone
  Future<List<Supplier>> searchSuppliers(String query);

  /// Get active suppliers only
  Future<List<Supplier>> getActiveSuppliers();

  /// Create new supplier
  Future<int> createSupplier(Supplier supplier);

  /// Update existing supplier
  Future<void> updateSupplier(Supplier supplier);

  /// Soft delete supplier
  Future<void> deleteSupplier(int id);

  /// Get supplier balance (amount we owe)
  Future<double> getSupplierBalance(int supplierId);

  /// Get supplier statement
  Future<Map<String, dynamic>> getSupplierStatement(
    int supplierId, {
    DateTime? fromDate,
    DateTime? toDate,
  });
}
