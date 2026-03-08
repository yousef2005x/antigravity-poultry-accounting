import 'package:poultry_accounting/backend/domain/entities/annual_inventory.dart';

abstract class AnnualInventoryRepository {
  Future<List<AnnualInventory>> getAllInventories({
    DateTime? fromDate,
    DateTime? toDate,
  });
  
  Stream<List<AnnualInventory>> watchAllInventories({
    DateTime? fromDate,
    DateTime? toDate,
  });
  
  Future<AnnualInventory?> getInventoryById(int id);
  Future<int> createInventory(AnnualInventory inventory);
  Future<void> updateInventory(AnnualInventory inventory);
  Future<void> deleteInventory(int id);
  
  Future<double> getTotalInventories({
    DateTime? fromDate,
    DateTime? toDate,
  });
}
