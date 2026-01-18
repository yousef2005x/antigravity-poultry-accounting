import 'package:poultry_accounting/domain/entities/product.dart';

/// Product Repository Interface
abstract class ProductRepository {
  /// Get all products
  Future<List<Product>> getAllProducts();

  /// Watch all products
  Stream<List<Product>> watchAllProducts();

  /// Get product by ID
  Future<Product?> getProductById(int id);

  /// Search products by name
  Future<List<Product>> searchProducts(String query);

  /// Get active products only
  Future<List<Product>> getActiveProducts();

  /// Create new product
  Future<int> createProduct(Product product);

  /// Update existing product
  Future<void> updateProduct(Product product);

  /// Soft delete product
  Future<void> deleteProduct(int id);

  /// Get current stock for product
  Future<double> getCurrentStock(int productId);

  /// Get average cost for product (FIFO or weighted average)
  Future<double> getAverageCost(int productId);

  /// Get product with stock info
  Future<Product> getProductWithStock(int productId);

  /// Get low stock products
  Future<List<Product>> getLowStockProducts({double threshold = 10.0});
}
