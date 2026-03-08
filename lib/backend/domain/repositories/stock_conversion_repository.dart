import 'package:poultry_accounting/backend/domain/entities/stock_conversion.dart';

abstract class StockConversionRepository {
  Future<List<StockConversion>> getAllConversions();
  
  Future<StockConversion?> getConversionById(int id);
  
  Future<List<StockConversionItem>> getItemsByConversionId(int conversionId);

  /// Performs the conversion:
  /// 1. Deducts [sourceQuantity] of [sourceProductId] from inventory.
  /// 2. Creates a conversion record.
  /// 3. Adds [items] to inventory (as new batches) ONLY if they are intermediate or forceInventory is true.
  /// Returns the list of items with calculated unit costs.
  Future<List<StockConversionItem>> convertStock({
    required StockConversion conversion,
    required List<StockConversionItem> items,
    bool forceInventory = false,
  });
}
