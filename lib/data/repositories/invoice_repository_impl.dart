import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {

  InvoiceRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<Invoice>> getAllInvoices({
    InvoiceStatus? status,
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.salesInvoices).join([
      leftOuterJoin(database.customers, database.customers.id.equalsExp(database.salesInvoices.customerId)),
    ]);
    
    if (status != null) {
      query.where(database.salesInvoices.status.equals(status.code));
    }
    if (customerId != null) {
      query.where(database.salesInvoices.customerId.equals(customerId));
    }
    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    
    final results = await query.get();
    final List<Invoice> invoices = [];
    
    for (final row in results) {
      final invoiceRow = row.readTable(database.salesInvoices);
      final customerRow = row.readTableOrNull(database.customers);
      
      final items = await _getInvoiceItems(invoiceRow.id);
      invoices.add(_mapToEntity(invoiceRow, items, customer: customerRow != null ? _mapToCustomerEntity(customerRow) : null));
    }
    
    return invoices;
  }

  @override
  Stream<List<Invoice>> watchAllInvoices({
    InvoiceStatus? status,
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final query = database.select(database.salesInvoices).join([
      leftOuterJoin(database.customers, database.customers.id.equalsExp(database.salesInvoices.customerId)),
    ]);

    if (status != null) {
      query.where(database.salesInvoices.status.equals(status.code));
    }
    if (customerId != null) {
      query.where(database.salesInvoices.customerId.equals(customerId));
    }
    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }

    return query.watch().asyncMap((results) async {
      final List<Invoice> invoices = [];
      for (final row in results) {
        final invoiceRow = row.readTable(database.salesInvoices);
        final customerRow = row.readTableOrNull(database.customers);

        final items = await _getInvoiceItems(invoiceRow.id);
        invoices.add(_mapToEntity(invoiceRow, items, customer: customerRow != null ? _mapToCustomerEntity(customerRow) : null));
      }
      return invoices;
    });
  }

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    final query = database.select(database.salesInvoices).join([
      leftOuterJoin(database.customers, database.customers.id.equalsExp(database.salesInvoices.customerId)),
    ])..where(database.salesInvoices.id.equals(id));
    
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    
    final invoiceRow = row.readTable(database.salesInvoices);
    final customerRow = row.readTableOrNull(database.customers);
    
    final items = await _getInvoiceItems(invoiceRow.id);
    return _mapToEntity(invoiceRow, items, customer: customerRow != null ? _mapToCustomerEntity(customerRow) : null);
  }

  @override
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final query = database.select(database.salesInvoices).join([
      leftOuterJoin(database.customers, database.customers.id.equalsExp(database.salesInvoices.customerId)),
    ])..where(database.salesInvoices.invoiceNumber.equals(invoiceNumber));
    
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    
    final invoiceRow = row.readTable(database.salesInvoices);
    final customerRow = row.readTableOrNull(database.customers);
    
    final items = await _getInvoiceItems(invoiceRow.id);
    return _mapToEntity(invoiceRow, items, customer: customerRow != null ? _mapToCustomerEntity(customerRow) : null);
  }

  @override
  Future<int> createInvoice(Invoice invoice) async {
    return database.transaction(() async {
      final id = await database.into(database.salesInvoices).insert(
        db.SalesInvoicesCompanion.insert(
          invoiceNumber: invoice.invoiceNumber,
          customerId: invoice.customerId,
          invoiceDate: invoice.invoiceDate,
          status: invoice.status.code,
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          notes: Value(invoice.notes),
          createdBy: invoice.createdBy ?? 1,
        ),
      );

      for (final item in invoice.items) {
        await database.into(database.salesInvoiceItems).insert(
          db.SalesInvoiceItemsCompanion.insert(
            invoiceId: id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            costAtSale: item.costAtSale,
            discount: Value(item.discount),
            total: item.total,
          ),
        );
      }
      
      if (invoice.paidAmount > 0) {
        await _syncPaymentForInvoice(id, invoice.paidAmount, invoice.customerId, invoice.invoiceDate);
      }

      return id;
    });
  }

  @override
  Future<void> updateInvoice(Invoice invoice) async {
    if (invoice.id == null) {
      return;
    }
    
    await database.transaction(() async {
      await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoice.id!))).write(
        db.SalesInvoicesCompanion(
          customerId: Value(invoice.customerId),
          invoiceDate: Value(invoice.invoiceDate),
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          notes: Value(invoice.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Re-insert items
      await (database.delete(database.salesInvoiceItems)..where((t) => t.invoiceId.equals(invoice.id!))).go();
      for (final item in invoice.items) {
        await database.into(database.salesInvoiceItems).insert(
          db.SalesInvoiceItemsCompanion.insert(
            invoiceId: invoice.id!,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            costAtSale: item.costAtSale,
            discount: Value(item.discount),
            total: item.total,
          ),
        );
      }

      if (invoice.paidAmount > 0) {
        await _syncPaymentForInvoice(invoice.id!, invoice.paidAmount, invoice.customerId, invoice.invoiceDate);
      }
    });
  }

  @override
  Future<void> confirmInvoice(int invoiceId, int userId) async {
    await database.transaction(() async {
      // 1. Get invoice items
      final items = await _getInvoiceItems(invoiceId);
      
      for (final item in items) {
        if (item.productId == 0) {
          continue;
        } // Skip non-product items if any

        double remainingToDeduct = item.quantity;
        double totalCost = 0;

        // 2. Fetch available batches for this product (FIFO)
        final batches = await (database.select(database.inventoryBatches)
              ..where((t) => t.productId.equals(item.productId) & t.remainingQuantity.isBiggerThanValue(0))
              ..orderBy([(t) => OrderingTerm(expression: t.purchaseDate)]))
            .get();

        // 3. Deduct from batches
        for (final batch in batches) {
          if (remainingToDeduct <= 0) {
            break;
          }

          final deductAmount = (batch.remainingQuantity >= remainingToDeduct)
              ? remainingToDeduct
              : batch.remainingQuantity;

          // Update batch
          await (database.update(database.inventoryBatches)..where((t) => t.id.equals(batch.id))).write(
            db.InventoryBatchesCompanion(
              remainingQuantity: Value(batch.remainingQuantity - deductAmount),
            ),
          );

          totalCost += deductAmount * batch.unitCost;
          remainingToDeduct -= deductAmount;
        }

        if (remainingToDeduct > 0) {
          throw Exception('Insufficient stock for product ID: ${item.productId}. Missing: $remainingToDeduct');
        }

        // 4. Update item cost
        final averageCost = totalCost / item.quantity;
        await (database.update(database.salesInvoiceItems)..where((t) => t.id.equals(item.id!))).write(
          db.SalesInvoiceItemsCompanion(
            costAtSale: Value(averageCost),
          ),
        );
      }

      // 5. Update invoice status
      await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
        db.SalesInvoicesCompanion(
          status: Value(InvoiceStatus.confirmed.code),
          confirmedAt: Value(DateTime.now()),
          confirmedBy: Value(userId),
        ),
      );
    });
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    await database.transaction(() async {
      // 1. Get invoice to check if it was confirmed
      final invoice = await getInvoiceById(invoiceId);
      if (invoice == null) {
        return;
      }

      // 2. Only restore inventory if invoice was confirmed (stock was deducted)
      if (invoice.status == InvoiceStatus.confirmed) {
        for (final item in invoice.items) {
          // Create a restocked batch for each item
          await database.into(database.inventoryBatches).insert(
            db.InventoryBatchesCompanion.insert(
              productId: item.productId,
              quantity: item.quantity,
              remainingQuantity: item.quantity,
              unitCost: item.costAtSale,
              purchaseDate: DateTime.now(),
              batchNumber: Value('RESTOCK-INV-$invoiceId-${item.productId}'),
            ),
          );
        }
      }

      // 3. Update invoice status to cancelled
      await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
        db.SalesInvoicesCompanion(
          status: Value(InvoiceStatus.cancelled.code),
        ),
      );
    });
  }

  @override
  Future<void> deleteInvoice(int id) async {
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(id))).write(
      db.SalesInvoicesCompanion(
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<String> generateInvoiceNumber() async {
    final countExp = database.salesInvoices.id.count();
    final query = database.selectOnly(database.salesInvoices)..addColumns([countExp]);
    final count = await query.map((row) => row.read(countExp)).getSingle();
    final year = DateTime.now().year.toString().substring(2);
    return 'INV-$year-${((count ?? 0) + 1).toString().padLeft(5, '0')}';
  }

  @override
  Future<double> getTotalRevenue({DateTime? fromDate, DateTime? toDate}) async {
    final totalExp = database.salesInvoices.total.sum();
    final query = database.selectOnly(database.salesInvoices)..addColumns([totalExp]);
    query.where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code));
    
    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    
    final result = await query.getSingle();
    return result.read(totalExp) ?? 0.0;
  }

  @override
  Future<double> getTotalProfit({DateTime? fromDate, DateTime? toDate}) async {
    final totalRevenue = await getTotalRevenue(fromDate: fromDate, toDate: toDate);
    
    // Calculate real COGS: sum of (costAtSale * quantity) for all confirmed invoices
    final query = database.select(database.salesInvoiceItems).join([
      innerJoin(
        database.salesInvoices,
        database.salesInvoices.id.equalsExp(database.salesInvoiceItems.invoiceId),
      ),
    ]);
    
    query.where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code));
    
    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    
    final items = await query.get();
    double totalCogs = 0;
    for (final row in items) {
      final item = row.readTable(database.salesInvoiceItems);
      totalCogs += item.costAtSale * item.quantity;
    }
    
    return totalRevenue - totalCogs;
  }

  @override
  Future<List<Invoice>> getUnpaidInvoices(int customerId) async {
    final query = database.select(database.salesInvoices)
      ..where((t) => t.customerId.equals(customerId) & 
                     t.status.equals(InvoiceStatus.confirmed.code) &
                     t.total.isBiggerThan(t.paidAmount),);
    
    final rows = await query.get();
    final List<Invoice> invoices = [];
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      invoices.add(_mapToEntity(row, items));
    }
    return invoices;
  }

  @override
  Future<void> updatePaidAmount(int invoiceId, double amount) async {
    final invoice = await getInvoiceById(invoiceId);
    if (invoice == null) {
      return;
    }
    
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
      db.SalesInvoicesCompanion(
        paidAmount: Value(invoice.paidAmount + amount),
      ),
    );

    await _syncPaymentForInvoice(invoiceId, invoice.paidAmount + amount, invoice.customerId, DateTime.now());
  }

  Future<void> _syncPaymentForInvoice(int invoiceId, double paidAmount, int customerId, DateTime date) async {
    // 1. Check if a payment record already exists for this invoice
    final existing = await (database.select(database.payments)..where((t) => t.invoiceId.equals(invoiceId))).getSingleOrNull();

    if (paidAmount <= 0) {
      if (existing != null) {
        // If paidAmount was reset to 0, delete the payment
        await (database.delete(database.payments)..where((t) => t.id.equals(existing.id))).go();
        // Also delete from cash transactions
        await (database.delete(database.cashTransactions)..where((t) => t.relatedPaymentId.equals(existing.id))).go();
      }
      return;
    }

    if (existing != null) {
      // Update existing payment
      await (database.update(database.payments)..where((t) => t.id.equals(existing.id))).write(
        db.PaymentsCompanion(
          amount: Value(paidAmount),
          paymentDate: Value(date),
        ),
      );
      // Synchronize cash transaction if needed
      await (database.update(database.cashTransactions)..where((t) => t.relatedPaymentId.equals(existing.id))).write(
        db.CashTransactionsCompanion(
          amount: Value(paidAmount),
          transactionDate: Value(date),
        ),
      );
    } else {
      // Create new payment
      final prefix = 'REC-INV';
      final query = database.select(database.payments)..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])..limit(1);
      final last = await query.getSingleOrNull();
      final nextId = (last?.id ?? 0) + 1;
      final paymentNumber = '$prefix-${nextId.toString().padLeft(5, '0')}';

      final id = await database.into(database.payments).insert(
        db.PaymentsCompanion.insert(
          paymentNumber: paymentNumber,
          type: 'receipt',
          amount: paidAmount,
          method: PaymentMethod.cash.code, // Default to cash for invoice payments
          paymentDate: date,
          customerId: Value(customerId),
          invoiceId: Value(invoiceId),
          notes: Value('دفعة مقدمة للفاتورة رقم $invoiceId'),
          createdBy: 1,
        ),
      );

      // Create cash transaction
      await database.into(database.cashTransactions).insert(
        db.CashTransactionsCompanion.insert(
          amount: paidAmount,
          type: 'in',
          description: 'دفعة مقدمة للفاتورة رقم $invoiceId',
          transactionDate: date,
          relatedPaymentId: Value(id),
          createdBy: 1,
        ),
      );
    }
  }

  Customer _mapToCustomerEntity(db.CustomerTable row) {
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      address: row.address,
      creditLimit: row.creditLimit,
      notes: row.notes,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  // Helpers
  Future<List<InvoiceItem>> _getInvoiceItems(int invoiceId) async {
    final query = database.select(database.salesInvoiceItems).join([
      innerJoin(
        database.products,
        database.products.id.equalsExp(database.salesInvoiceItems.productId),
      ),
    ])
      ..where(database.salesInvoiceItems.invoiceId.equals(invoiceId));
    
    final rows = await query.get();
    return rows.map((row) {
      final item = row.readTable(database.salesInvoiceItems);
      final product = row.readTable(database.products);
      return InvoiceItem(
        id: item.id,
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costAtSale: item.costAtSale,
        discount: item.discount,
      );
    }).toList();
  }

  Invoice _mapToEntity(db.SalesInvoiceTable row, List<InvoiceItem> items, {Customer? customer}) {
    return Invoice(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
      customerId: row.customerId,
      customer: customer,
      invoiceDate: row.invoiceDate,
      status: InvoiceStatus.fromCode(row.status),
      items: items,
      discount: row.discount,
      tax: row.tax,
      paidAmount: row.paidAmount,
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
