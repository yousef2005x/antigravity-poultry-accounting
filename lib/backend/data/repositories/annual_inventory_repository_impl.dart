import 'package:drift/drift.dart';
import 'package:poultry_accounting/backend/data/database/database.dart' as db;
import 'package:poultry_accounting/backend/domain/entities/annual_inventory.dart';
import 'package:poultry_accounting/backend/domain/repositories/annual_inventory_repository.dart';

class AnnualInventoryRepositoryImpl implements AnnualInventoryRepository {
  AnnualInventoryRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<AnnualInventory>> getAllInventories({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.annualInventories);

    if (fromDate != null) {
      query.where((t) => t.inventoryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.inventoryDate.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.inventoryDate)]);

    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<AnnualInventory>> watchAllInventories({
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return database
        .select(database.annualInventories)
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<AnnualInventory?> getInventoryById(int id) async {
    final query = database.select(database.annualInventories)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createInventory(AnnualInventory inventory) {
    return database.into(database.annualInventories).insert(
          db.AnnualInventoriesCompanion.insert(
            amount: inventory.amount,
            inventoryDate: inventory.inventoryDate,
            description: inventory.description,
            createdBy: inventory.createdBy ?? 1,
          ),
        );
  }

  @override
  Future<void> updateInventory(AnnualInventory inventory) {
    return (database.update(database.annualInventories)..where((t) => t.id.equals(inventory.id!)))
        .write(
      db.AnnualInventoriesCompanion(
        amount: Value(inventory.amount),
        inventoryDate: Value(inventory.inventoryDate),
        description: Value(inventory.description),
      ),
    );
  }

  @override
  Future<void> deleteInventory(int id) {
    return (database.delete(database.annualInventories)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<double> getTotalInventories({DateTime? fromDate, DateTime? toDate}) async {
    final amountExp = database.annualInventories.amount.sum();
    final query = database.selectOnly(database.annualInventories)..addColumns([amountExp]);

    if (fromDate != null) {
      query.where(database.annualInventories.inventoryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.annualInventories.inventoryDate.isSmallerOrEqualValue(toDate));
    }

    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  AnnualInventory _mapToEntity(db.AnnualInventoryTable row) {
    return AnnualInventory(
      id: row.id,
      amount: row.amount,
      inventoryDate: row.inventoryDate,
      description: row.description,
      createdBy: row.createdBy,
    );
  }
}
