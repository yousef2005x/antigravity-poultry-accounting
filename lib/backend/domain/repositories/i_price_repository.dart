import 'package:poultry_accounting/backend/domain/entities/product_price.dart';

abstract class IPriceRepository {
  Future<List<ProductPrice>> getPricesByDate(DateTime date);
  Future<ProductPrice?> getLatestPrice(int productId);
  Future<void> updatePrice(ProductPrice price);
  Future<void> updateMultiplePrices(List<ProductPrice> prices);
  Future<List<ProductPrice>> getPriceHistory(int productId, DateTime start, DateTime end);
}
