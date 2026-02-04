import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/purchase_invoice.dart' as domain;
import 'package:poultry_accounting/domain/repositories/purchase_repository.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  PurchaseRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<domain.PurchaseInvoice>> getAllPurchaseInvoices({
    InvoiceStatus? status,
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.purchaseInvoices);
    if (status != null) {
      query.where((t) => t.status.equals(status.toString()));
    }
    if (supplierId != null) {
      query.where((t) => t.supplierId.equals(supplierId));
    }
    
    final rows = await query.get();
    final List<domain.PurchaseInvoice> invoices = [];
    
    for (final row in rows) {
      final items = await _getItemsForInvoice(row.id);
      invoices.add(_mapToEntity(row, items));
    }
    
    return invoices;
  }

  @override
  Stream<List<domain.PurchaseInvoice>> watchAllPurchaseInvoices() {
    return database.select(database.purchaseInvoices).watch().asyncMap((rows) async {
      final List<domain.PurchaseInvoice> invoices = [];
      for (final row in rows) {
        final items = await _getItemsForInvoice(row.id);
        invoices.add(_mapToEntity(row, items));
      }
      return invoices;
    });
  }

  @override
  Future<domain.PurchaseInvoice?> getPurchaseInvoiceById(int id) async {
    final query = database.select(database.purchaseInvoices)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    
    final items = await _getItemsForInvoice(row.id);
    return _mapToEntity(row, items);
  }

  @override
  Future<int> createPurchaseInvoice(domain.PurchaseInvoice invoice) async {
    return database.transaction(() async {
      final id = await database.into(database.purchaseInvoices).insert(
        db.PurchaseInvoicesCompanion.insert(
          invoiceNumber: invoice.invoiceNumber,
          supplierId: invoice.supplierId,
          invoiceDate: invoice.invoiceDate,
          status: invoice.status.name,
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          additionalCosts: Value(invoice.additionalCosts),
          notes: Value(invoice.notes),
          createdBy: 1, // TODO Bug 8: Replace with actual user ID from AuthProvider
        ),
      );

      for (final item in invoice.items) {
        await database.into(database.purchaseInvoiceItems).insert(
          db.PurchaseInvoiceItemsCompanion.insert(
            invoiceId: id,
            productId: item.productId,
            quantity: item.quantity,
            unitCost: item.unitCost,
            total: item.calculatedTotal,
          ),
        );
      }
      
      return id;
    });
  }

  @override
  Future<void> updatePurchaseInvoice(domain.PurchaseInvoice invoice) async {
    await database.transaction(() async {
      await (database.update(database.purchaseInvoices)..where((t) => t.id.equals(invoice.id!))).write(
        db.PurchaseInvoicesCompanion(
          supplierId: Value(invoice.supplierId),
          invoiceDate: Value(invoice.invoiceDate),
          status: Value(invoice.status.name),
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          additionalCosts: Value(invoice.additionalCosts),
          notes: Value(invoice.notes),
        ),
      );

      // Simple approach: delete and re-insert items
      await (database.delete(database.purchaseInvoiceItems)..where((t) => t.invoiceId.equals(invoice.id!))).go();
      
      for (final item in invoice.items) {
        await database.into(database.purchaseInvoiceItems).insert(
          db.PurchaseInvoiceItemsCompanion.insert(
            invoiceId: invoice.id!,
            productId: item.productId,
            quantity: item.quantity,
            unitCost: item.unitCost,
            total: item.calculatedTotal,
          ),
        );
      }
    });
  }

  @override
  Future<void> confirmPurchaseInvoice(int invoiceId, int userId) async {
    await database.transaction(() async {
      final invoice = await getPurchaseInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }
      
      await (database.update(database.purchaseInvoices)..where((t) => t.id.equals(invoiceId))).write(
        db.PurchaseInvoicesCompanion(
          status: Value(InvoiceStatus.confirmed.name),
          confirmedAt: Value(DateTime.now()),
          confirmedBy: Value(userId),
        ),
      );

      // Create inventory batches
      for (final item in invoice.items) {
        await database.into(database.inventoryBatches).insert(
          db.InventoryBatchesCompanion.insert(
            productId: item.productId,
            purchaseInvoiceId: Value(invoiceId),
            quantity: item.quantity,
            remainingQuantity: item.quantity,
            unitCost: item.unitCost,
            purchaseDate: invoice.invoiceDate,
          ),
        );
      }
    });
  }

  @override
  Future<void> deletePurchaseInvoice(int id) async {
    await (database.update(database.purchaseInvoices)..where((t) => t.id.equals(id))).write(
      db.PurchaseInvoicesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<String> generatePurchaseInvoiceNumber() async {
    final query = database.select(database.purchaseInvoices)..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])..limit(1);
    final last = await query.getSingleOrNull();
    final nextId = (last?.id ?? 0) + 1;
    return 'PUR-$nextId';
  }

  @override
  Future<double> getTotalPurchases({DateTime? fromDate, DateTime? toDate}) async {
    final query = database.selectOnly(database.purchaseInvoices);
    final totalExp = database.purchaseInvoices.total.sum();
    query.addColumns([totalExp]);
    query.where(database.purchaseInvoices.status.equals(InvoiceStatus.confirmed.name));
    
    final row = await query.getSingle();
    return row.read(totalExp) ?? 0.0;
  }

  Future<List<domain.PurchaseInvoiceItem>> _getItemsForInvoice(int invoiceId) async {
    final query = database.select(database.purchaseInvoiceItems)..where((t) => t.invoiceId.equals(invoiceId));
    final rows = await query.get();
    
    final List<domain.PurchaseInvoiceItem> items = [];
    for (final row in rows) {
      final productQuery = database.select(database.products)..where((t) => t.id.equals(row.productId));
      final pRow = await productQuery.getSingle();
      items.add(domain.PurchaseInvoiceItem(
        id: row.id,
        productId: row.productId,
        productName: pRow.name,
        quantity: row.quantity,
        unitCost: row.unitCost,
        total: row.total,
      ),);
    }
    return items;
  }

  domain.PurchaseInvoice _mapToEntity(db.PurchaseInvoiceTable row, List<domain.PurchaseInvoiceItem> items) {
    return domain.PurchaseInvoice(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
      supplierId: row.supplierId,
      invoiceDate: row.invoiceDate,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => InvoiceStatus.draft,
      ),
      items: items,
      discount: row.discount,
      tax: row.tax,
      paidAmount: row.paidAmount,
      additionalCosts: row.additionalCosts,
      notes: row.notes,
      createdBy: row.createdBy,
      confirmedAt: row.confirmedAt,
      confirmedBy: row.confirmedBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
