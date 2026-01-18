import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/product.dart' as domain;
import 'package:poultry_accounting/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {

  ProductRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<domain.Product>> getAllProducts() async {
    final rows = await database.select(database.products).get();
    return rows.map(_mapToEntity).toList().cast<domain.Product>();
  }

  @override
  Stream<List<domain.Product>> watchAllProducts() {
    return database.select(database.products).watch().map((rows) => rows.map(_mapToEntity).toList().cast<domain.Product>());
  }

  @override
  Future<domain.Product?> getProductById(int id) async {
    final query = database.select(database.products)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createProduct(domain.Product product) async {
    return database.into(database.products).insert(
      db.ProductsCompanion.insert(
        name: product.name,
        unitType: product.unitType.code,
        isWeighted: Value(product.isWeighted),
        defaultPrice: Value(product.defaultPrice),
        description: Value(product.description),
      ),
    );
  }

  @override
  Future<void> updateProduct(domain.Product product) async {
    await (database.update(database.products)..where((t) => t.id.equals(product.id!))).write(
      db.ProductsCompanion(
        name: Value(product.name),
        unitType: Value(product.unitType.code),
        isWeighted: Value(product.isWeighted),
        defaultPrice: Value(product.defaultPrice),
        description: Value(product.description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (database.update(database.products)..where((t) => t.id.equals(id))).write(
      db.ProductsCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<List<domain.Product>> getActiveProducts() async {
    final query = database.select(database.products)..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapToEntity).toList().cast<domain.Product>();
  }

  domain.Product _mapToEntity(db.ProductTable row) {
    return domain.Product(
      id: row.id,
      name: row.name,
      unitType: UnitType.fromCode(row.unitType),
      isWeighted: row.isWeighted,
      defaultPrice: row.defaultPrice,
      description: row.description,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
  
  @override
  Future<List<domain.Product>> searchProducts(String query) async {
    final results = await (database.select(database.products)..where((t) => t.name.like('%$query%'))).get();
    return results.map(_mapToEntity).toList().cast<domain.Product>();
  }

  @override
  Future<double> getCurrentStock(int productId) async {
    // Current stock = Sum(inventory_batches.remainingQuantity)
    final quantityExp = database.inventoryBatches.remainingQuantity.sum();
    final query = database.selectOnly(database.inventoryBatches)
      ..addColumns([quantityExp])
      ..where(database.inventoryBatches.productId.equals(productId));
    
    final result = await query.getSingle();
    return result.read(quantityExp) ?? 0.0;
  }

  @override
  Future<double> getAverageCost(int productId) async {
    // Weighted Average Cost = Total Cost of remaining stock / Total remaining quantity
    final totalCostExp = (database.inventoryBatches.remainingQuantity * database.inventoryBatches.unitCost).sum();
    final totalQtyExp = database.inventoryBatches.remainingQuantity.sum();
    
    final query = database.selectOnly(database.inventoryBatches)
      ..addColumns([totalCostExp, totalQtyExp])
      ..where(database.inventoryBatches.productId.equals(productId));
    
    final result = await query.getSingle();
    final totalCost = result.read(totalCostExp) ?? 0.0;
    final totalQty = result.read(totalQtyExp) ?? 0.0;
    
    if (totalQty == 0) {
      return 0.0;
    }
    return totalCost / totalQty;
  }

  @override
  Future<domain.Product> getProductWithStock(int productId) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }
    
    final stock = await getCurrentStock(productId);
    final cost = await getAverageCost(productId);
    
    return product.copyWith(
      currentStock: stock,
      averageCost: cost,
    );
  }

  @override
  Future<List<domain.Product>> getLowStockProducts({double threshold = 10.0}) async {
    // This requires a join or a complex subquery in Drift.
    // For simplicity, we'll get active products and filter in memory or do a specific query if possible.
    final allActive = await getActiveProducts();
    final List<domain.Product> lowStock = [];
    
    for (final product in allActive) {
      final stock = await getCurrentStock(product.id!);
      if (stock <= threshold) {
        lowStock.add(product);
      }
    }
    return lowStock;
  }
}
