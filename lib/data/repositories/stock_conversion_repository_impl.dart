import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/stock_conversion.dart';
import 'package:poultry_accounting/domain/repositories/stock_conversion_repository.dart';

class StockConversionRepositoryImpl implements StockConversionRepository {
  StockConversionRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<StockConversion>> getAllConversions() async {
    final rows = await database.select(database.stockConversions).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<StockConversion?> getConversionById(int id) async {
    final row = await (database.select(database.stockConversions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<StockConversionItem>> getItemsByConversionId(int conversionId) async {
    final rows = await (database.select(database.stockConversionItems)..where((t) => t.conversionId.equals(conversionId))).get();
    return rows.map(_mapItemToEntity).toList();
  }

  @override
  Future<List<StockConversionItem>> convertStock({
    required StockConversion conversion,
    required List<StockConversionItem> items,
    bool forceInventory = false,
  }) async {
    return database.transaction(() async {
      // 1. Create Conversion Record
      final conversionId = await database.into(database.stockConversions).insert(
        db.StockConversionsCompanion.insert(
          conversionDate: conversion.conversionDate,
          sourceProductId: conversion.sourceProductId,
          sourceQuantity: conversion.sourceQuantity,
          batchNumber: Value(conversion.batchNumber),
          notes: Value(conversion.notes),
          createdBy: conversion.createdBy,
        ),
      );

      // 2. Reduce Stock of Source Product (FIFO)
      double remainingToDeduct = conversion.sourceQuantity;
      
      final batches = await (database.select(database.inventoryBatches)
        ..where((t) => t.productId.equals(conversion.sourceProductId))
        ..where((t) => t.remainingQuantity.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.asc(t.purchaseDate)]))
        .get();

      double weightedCostSum = 0;

      for (final batch in batches) {
        if (remainingToDeduct <= 0) {
          break;
        }

        double deductAmount = 0;
        if (batch.remainingQuantity >= remainingToDeduct) {
          deductAmount = remainingToDeduct;

          await (database.update(database.inventoryBatches)
                ..where((t) => t.id.equals(batch.id)))
              .write(
            db.InventoryBatchesCompanion(
              remainingQuantity: Value(batch.remainingQuantity - deductAmount),
            ),
          );
          remainingToDeduct = 0;
        } else {
          deductAmount = batch.remainingQuantity;
          await (database.update(database.inventoryBatches)
                ..where((t) => t.id.equals(batch.id)))
              .write(
            const db.InventoryBatchesCompanion(
              remainingQuantity: Value(0),
            ),
          );
          remainingToDeduct -= deductAmount;
        }

        weightedCostSum += deductAmount * batch.unitCost;
      }

      if (remainingToDeduct > 0.01) {
        throw Exception('لا يوجد مخزون كافٍ من المنتج المختار لإجراء التحويل.');
      }

      final totalSourceCost = weightedCostSum;
      final totalOutputWeight = items.fold(0.0, (sum, item) => sum + item.quantity);
      final List<StockConversionItem> processedItems = [];

      // 3. Add Items & Create New Batches
      // Bug 6 Note: Cost is allocated by weight (simple but not accurate for products of different value).
      // A more accurate approach would use value-based ratios (e.g., Breast = 3x, Bones = 0.2x).
      // TODO: Consider adding costRatio field to StockConversionItem for weighted value allocation.
      for (final item in items) {
        double assignedCost = 0;
        if (totalOutputWeight > 0) {
           assignedCost = (item.quantity / totalOutputWeight) * totalSourceCost;
        }
        
        final outputUnitCost = item.quantity > 0 ? (assignedCost / item.quantity) : 0.0;

        final itemId = await database.into(database.stockConversionItems).insert(
          db.StockConversionItemsCompanion.insert(
            conversionId: conversionId,
            productId: item.productId,
            quantity: item.quantity,
            yieldPercentage: item.yieldPercentage,
            unitCost: outputUnitCost,
          ),
        );

        processedItems.add(StockConversionItem(
          id: itemId,
          conversionId: conversionId,
          productId: item.productId,
          quantity: item.quantity,
          yieldPercentage: item.yieldPercentage,
          unitCost: outputUnitCost,
        ),);

        // Fetch product type to decide on inventory entry
        final product = await (database.select(database.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
        final bool isIntermediate = product?.productType == 'intermediate';

        // Add to Inventory ONLY if it's intermediate OR forced
        if (isIntermediate || forceInventory) {
          await database.into(database.inventoryBatches).insert(
            db.InventoryBatchesCompanion.insert(
              productId: item.productId,
              processingId: Value(conversionId),
              quantity: item.quantity,
              remainingQuantity: item.quantity,
              unitCost: outputUnitCost,
              purchaseDate: conversion.conversionDate,
              batchNumber: Value('CONV-$conversionId-${item.productId}'),
            ),
          );
        }
      }

      return processedItems;
    });
  }

  StockConversion _mapToEntity(db.StockConversionTable row) {
    return StockConversion(
      id: row.id,
      conversionDate: row.conversionDate,
      sourceProductId: row.sourceProductId,
      sourceQuantity: row.sourceQuantity,
      batchNumber: row.batchNumber,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }

  StockConversionItem _mapItemToEntity(db.StockConversionItemTable row) {
    return StockConversionItem(
      id: row.id,
      conversionId: row.conversionId,
      productId: row.productId,
      quantity: row.quantity,
      yieldPercentage: row.yieldPercentage,
      unitCost: row.unitCost,
    );
  }
}
