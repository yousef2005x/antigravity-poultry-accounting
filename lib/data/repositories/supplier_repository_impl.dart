import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/supplier.dart' as domain;
import 'package:poultry_accounting/domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<domain.Supplier>> getAllSuppliers() async {
    final rows = await database.select(database.suppliers).get();
    return rows.map(_mapToEntity).toList().cast<domain.Supplier>();
  }

  @override
  Stream<List<domain.Supplier>> watchAllSuppliers() {
    return database.select(database.suppliers).watch().map((rows) => rows.map(_mapToEntity).toList().cast<domain.Supplier>());
  }

  @override
  Future<domain.Supplier?> getSupplierById(int id) async {
    final query = database.select(database.suppliers)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createSupplier(domain.Supplier supplier) {
    return database.into(database.suppliers).insert(
      db.SuppliersCompanion.insert(
        name: supplier.name,
        phone: Value(supplier.phone),
        address: Value(supplier.address),
        notes: Value(supplier.notes),
      ),
    );
  }

  @override
  Future<void> updateSupplier(domain.Supplier supplier) async {
    await (database.update(database.suppliers)..where((t) => t.id.equals(supplier.id!))).write(
      db.SuppliersCompanion(
        name: Value(supplier.name),
        phone: Value(supplier.phone),
        address: Value(supplier.address),
        notes: Value(supplier.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteSupplier(int id) async {
    await (database.update(database.suppliers)..where((t) => t.id.equals(id))).write(
      db.SuppliersCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<List<domain.Supplier>> getActiveSuppliers() async {
    final query = database.select(database.suppliers)..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapToEntity).toList().cast<domain.Supplier>();
  }

  @override
  Future<List<domain.Supplier>> searchSuppliers(String query) async {
    final results = await (database.select(database.suppliers)..where((t) => t.name.like('%$query%') | t.phone.like('%$query%'))).get();
    return results.map(_mapToEntity).toList().cast<domain.Supplier>();
  }

  @override
  Future<double> getSupplierBalance(int supplierId) async {
    // Basic implementation: Confirmed Purchase Invoices - Paid Amount
    final query = database.select(database.purchaseInvoices)
      ..where((t) => t.supplierId.equals(supplierId) & t.status.equals('confirmed'));
    final invoices = await query.get();
    double balance = 0;
    for (final inv in invoices) {
      balance += inv.total - inv.paidAmount;
    }
    return balance;
  }

  @override
  Future<Map<String, dynamic>> getSupplierStatement(int supplierId, {DateTime? fromDate, DateTime? toDate}) async {
    return {}; // Placeholder
  }

  domain.Supplier _mapToEntity(db.SupplierTable row) {
    return domain.Supplier(
      id: row.id,
      name: row.name,
      phone: row.phone,
      address: row.address,
      notes: row.notes,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
