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
          grossWeight: processing.grossWeight,
          basketWeight: processing.basketWeight,
          basketCount: processing.basketCount,
          netWeight: processing.netWeight,
          totalCost: Value(processing.totalCost),
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
      final outputUnitCost = totalOutputQty > 0 ? (processing.totalCost / totalOutputQty) : 0.0;

      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputsCompanion.insert(
            processingId: id,
            productId: output.productId,
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
          ),
        );

        // Create Inventory Batch for the output
        await database.into(database.inventoryBatches).insert(
          db.InventoryBatchesCompanion.insert(
            productId: output.productId,
            processingId: Value(id), // Link to processing
            quantity: output.quantity,
            remainingQuantity: output.quantity, // New stock
            unitCost: outputUnitCost,
            purchaseDate: processing.processingDate,
            batchNumber: Value('${processing.batchNumber}-${output.productId}'),
          ),
        );
      }
      return id;
    });
  }

  @override
  Future<void> updateProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs) async {
    await database.transaction(() async {
      await (database.update(database.rawMeatProcessings)..where((t) => t.id.equals(processing.id!))).write(
        db.RawMeatProcessingsCompanion(
          grossWeight: Value(processing.grossWeight),
          basketWeight: Value(processing.basketWeight),
          basketCount: Value(processing.basketCount),
          netWeight: Value(processing.netWeight),
          totalCost: Value(processing.totalCost),
          notes: Value(processing.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Delete old outputs and replace with new ones
      await (database.delete(database.processingOutputs)..where((t) => t.processingId.equals(processing.id!))).go();
      
      // Delete associated inventory batches to reset stock (Assumption: Not yet sold)
      await (database.delete(database.inventoryBatches)..where((t) => t.processingId.equals(processing.id!))).go();

      double totalOutputQty = 0;
      for (final output in outputs) {
        totalOutputQty += output.quantity;
      }
      final outputUnitCost = totalOutputQty > 0 ? (processing.totalCost / totalOutputQty) : 0.0;

      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputsCompanion.insert(
            processingId: processing.id!,
            productId: output.productId,
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
          ),
        );

        // Re-create Inventory Batch
        await database.into(database.inventoryBatches).insert(
          db.InventoryBatchesCompanion.insert(
            productId: output.productId,
            processingId: Value(processing.id),
            quantity: output.quantity,
            remainingQuantity: output.quantity,
            unitCost: outputUnitCost,
            purchaseDate: processing.processingDate,
            batchNumber: Value('${processing.batchNumber}-${output.productId}'),
          ),
        );
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
      grossWeight: row.grossWeight,
      basketWeight: row.basketWeight,
      basketCount: row.basketCount,
      netWeight: row.netWeight,
      totalCost: row.totalCost,
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
      quantity: row.quantity,
      yieldPercentage: row.yieldPercentage,
      createdAt: row.createdAt,
    );
  }
}
