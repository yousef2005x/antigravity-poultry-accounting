import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';
import 'package:poultry_accounting/domain/repositories/i_processing_repository.dart';

class ProcessingRepositoryImpl implements IProcessingRepository {

  ProcessingRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<RawMeatProcessing>> getAllProcessings() async {
    final results = await database.select(database.rawMeatProcessings).get();
    return results.map(_mapToRawEntity).toList();
  }

  @override
  Future<RawMeatProcessing?> getProcessingById(int id) async {
    final query = database.select(database.rawMeatProcessings)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToRawEntity(result) : null;
  }

  @override
  Future<int> createProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs) async {
    return database.transaction(() async {
      final id = await database.into(database.rawMeatProcessings).insert(
        db.RawMeatProcessingsCompanion.insert(
          batchNumber: processing.batchNumber,
          liveGrossWeight: Value(processing.liveGrossWeight),
          liveCrateWeight: Value(processing.liveCrateWeight),
          liveCrateCount: Value(processing.liveCrateCount),
          liveNetWeight: Value(processing.liveNetWeight),
          slaughteredGrossWeight: Value(processing.slaughteredGrossWeight),
          slaughteredBasketWeight: Value(processing.slaughteredBasketWeight),
          slaughteredBasketCount: Value(processing.slaughteredBasketCount),
          slaughteredNetWeight: Value(processing.slaughteredNetWeight),
          netWeight: processing.netWeight, // Overall summary weight
          totalCost: Value(processing.totalCost),
          operationalExpenses: Value(processing.operationalExpenses),
          supplierId: Value(processing.supplierId),
          processingDate: processing.processingDate,
          notes: Value(processing.notes),
          createdBy: processing.createdBy,
        ),
      );

      double totalOutputQty = 0;
      for (final output in outputs) {
        totalOutputQty += output.quantity;
      }
      // Unit cost = (total incoming cost + operational expenses) / total useful output quantity
      final outputUnitCost = totalOutputQty > 0 ? ((processing.totalCost + processing.operationalExpenses) / totalOutputQty) : 0.0;

      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputsCompanion.insert(
            processingId: id,
            productId: output.productId,
            grossWeight: Value(output.grossWeight),
            basketWeight: Value(output.basketWeight),
            basketCount: Value(output.basketCount),
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
            inventoryDate: Value(output.inventoryDate),
          ),
        );

        // Fetch product type to decide on inventory entry
        final product = await (database.select(database.products)..where((t) => t.id.equals(output.productId))).getSingleOrNull();
        final bool isIntermediate = product?.productType == 'intermediate';

        // Create Inventory Batch ONLY for strictly allowed types (Intermediate/Whole)
        if (isIntermediate) {
          await database.into(database.inventoryBatches).insert(
            db.InventoryBatchesCompanion.insert(
              productId: output.productId,
              processingId: Value(id),
              quantity: output.quantity,
              remainingQuantity: output.quantity,
              unitCost: outputUnitCost,
              purchaseDate: output.inventoryDate ?? processing.processingDate,
              batchNumber: Value('${processing.batchNumber}-${output.productId}'),
            ),
          );
        }
      }
      return id;
    });
  }

  @override
  Future<void> updateProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs) async {
    // Check if any inventory has been sold from batches linked to this processing
    final batches = await (database.select(database.inventoryBatches)
      ..where((t) => t.processingId.equals(processing.id!))).get();

    for (final batch in batches) {
      if (batch.remainingQuantity < batch.quantity) {
        throw Exception('لا يمكن تعديل دفعة التجهيز لأن هناك مبيعات تمت من المخزون المرتبط بها. الكمية المباعة: ${batch.quantity - batch.remainingQuantity} كغ');
      }
    }

    await database.transaction(() async {
      await (database.update(database.rawMeatProcessings)..where((t) => t.id.equals(processing.id!))).write(
        db.RawMeatProcessingsCompanion(
          liveGrossWeight: Value(processing.liveGrossWeight),
          liveCrateWeight: Value(processing.liveCrateWeight),
          liveCrateCount: Value(processing.liveCrateCount),
          liveNetWeight: Value(processing.liveNetWeight),
          slaughteredGrossWeight: Value(processing.slaughteredGrossWeight),
          slaughteredBasketWeight: Value(processing.slaughteredBasketWeight),
          slaughteredBasketCount: Value(processing.slaughteredBasketCount),
          slaughteredNetWeight: Value(processing.slaughteredNetWeight),
          netWeight: Value(processing.netWeight),
          totalCost: Value(processing.totalCost),
          operationalExpenses: Value(processing.operationalExpenses),
          notes: Value(processing.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Delete old outputs and replace (safe since we verified no sales)
      await (database.delete(database.processingOutputs)..where((t) => t.processingId.equals(processing.id!))).go();
      await (database.delete(database.inventoryBatches)..where((t) => t.processingId.equals(processing.id!))).go();

      double totalOutputQty = 0;
      for (final output in outputs) {
        totalOutputQty += output.quantity;
      }
      final outputUnitCost = totalOutputQty > 0 ? ((processing.totalCost + processing.operationalExpenses) / totalOutputQty) : 0.0;

      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputsCompanion.insert(
            processingId: processing.id!,
            productId: output.productId,
            grossWeight: Value(output.grossWeight),
            basketWeight: Value(output.basketWeight),
            basketCount: Value(output.basketCount),
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
            inventoryDate: Value(output.inventoryDate),
          ),
        );

        // Fetch product type to decide on inventory entry
        final product = await (database.select(database.products)..where((t) => t.id.equals(output.productId))).getSingleOrNull();
        final bool isIntermediate = product?.productType == 'intermediate';

        if (isIntermediate) {
          await database.into(database.inventoryBatches).insert(
            db.InventoryBatchesCompanion.insert(
              productId: output.productId,
              processingId: Value(processing.id),
              quantity: output.quantity,
              remainingQuantity: output.quantity,
              unitCost: outputUnitCost,
              purchaseDate: output.inventoryDate ?? processing.processingDate,
              batchNumber: Value('${processing.batchNumber}-${output.productId}'),
            ),
          );
        }
      }
    });
  }

  @override
  Future<void> deleteProcessing(int id) async {
    await (database.delete(database.rawMeatProcessings)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<ProcessingOutput>> getOutputsByProcessingId(int processingId) async {
    final query = database.select(database.processingOutputs)..where((t) => t.processingId.equals(processingId));
    final results = await query.get();
    return results.map(_mapToOutputEntity).toList();
  }

  RawMeatProcessing _mapToRawEntity(db.RawMeatProcessingTable row) {
    return RawMeatProcessing(
      id: row.id,
      batchNumber: row.batchNumber,
      liveGrossWeight: row.liveGrossWeight,
      liveCrateWeight: row.liveCrateWeight,
      liveCrateCount: row.liveCrateCount,
      liveNetWeight: row.liveNetWeight,
      slaughteredGrossWeight: row.slaughteredGrossWeight,
      slaughteredBasketWeight: row.slaughteredBasketWeight,
      slaughteredBasketCount: row.slaughteredBasketCount,
      slaughteredNetWeight: row.slaughteredNetWeight,
      netWeight: row.netWeight,
      totalCost: row.totalCost,
      operationalExpenses: row.operationalExpenses,
      supplierId: row.supplierId,
      processingDate: row.processingDate,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ProcessingOutput _mapToOutputEntity(db.ProcessingOutputTable row) {
    return ProcessingOutput(
      id: row.id,
      processingId: row.processingId,
      productId: row.productId,
      grossWeight: row.grossWeight,
      basketWeight: row.basketWeight,
      basketCount: row.basketCount,
      quantity: row.quantity,
      yieldPercentage: row.yieldPercentage,
      createdAt: row.createdAt,
      inventoryDate: row.inventoryDate,
    );
  }
}
