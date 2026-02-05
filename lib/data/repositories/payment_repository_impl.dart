import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/customer.dart' as customer_domain;
import 'package:poultry_accounting/domain/entities/payment.dart' as domain;
import 'package:poultry_accounting/domain/entities/supplier.dart' as supplier_domain;
import 'package:poultry_accounting/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this.database);

  final db.AppDatabase database;

  @override
  Future<List<domain.Payment>> getAllPayments({
    String? type,
    int? customerId,
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.payments)
      ..where((t) {
        Expression<bool> predicate = const Constant(true);
        if (type != null) {
          predicate = predicate & t.type.equals(type);
        }
        if (customerId != null) {
          predicate = predicate & t.customerId.equals(customerId);
        }
        if (supplierId != null) {
          predicate = predicate & t.supplierId.equals(supplierId);
        }
        if (fromDate != null) {
          predicate = predicate & t.paymentDate.isBiggerOrEqualValue(fromDate);
        }
        if (toDate != null) {
          predicate = predicate & t.paymentDate.isSmallerOrEqualValue(toDate);
        }
        predicate = predicate & t.deletedAt.isNull();
        return predicate;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc)]);

    final rows = await query.get();
    return Future.wait(rows.map(_mapToEntity));
  }

  @override
  Future<domain.Payment?> getPaymentById(int id) async {
    final query = database.select(database.payments)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapToEntity(row);
  }

  @override
  Future<domain.Payment?> getPaymentByNumber(String paymentNumber) async {
    final query = database.select(database.payments)..where((t) => t.paymentNumber.equals(paymentNumber));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapToEntity(row);
  }

  @override
  Future<int> createReceipt(domain.Payment payment) async {
    return database.transaction(() async {
      // 1. Generate payment number if not provided
      final paymentNumber = payment.paymentNumber.isEmpty 
          ? await generatePaymentNumber() 
          : payment.paymentNumber;

      // 2. Insert payment
      final id = await database.into(database.payments).insert(
        db.PaymentsCompanion.insert(
          paymentNumber: paymentNumber,
          type: 'receipt',
          amount: payment.amount,
          method: payment.method.code,
          paymentDate: payment.paymentDate,
          customerId: Value(payment.customerId),
          referenceNumber: Value(payment.referenceNumber),
          notes: Value(payment.notes),
          createdBy: payment.createdBy ?? 1,
        ),
      );

      // 3. Create cash transaction if payment method is cash
      if (payment.method == PaymentMethod.cash) {
        await database.into(database.cashTransactions).insert(
          db.CashTransactionsCompanion.insert(
            amount: payment.amount,
            type: 'in',
            description: 'سند قبض رقم $paymentNumber',
            transactionDate: payment.paymentDate,
            relatedPaymentId: Value(id),
            createdBy: payment.createdBy ?? 1,
          ),
        );
      }

      return id;
    });
  }

  @override
  Future<int> createPayment(domain.Payment payment) async {
    return database.transaction(() async {
      // 1. Generate payment number
      final paymentNumber = payment.paymentNumber.isEmpty 
          ? await generatePaymentNumber('payment') 
          : payment.paymentNumber;

      // 2. Insert payment
      final id = await database.into(database.payments).insert(
        db.PaymentsCompanion.insert(
          paymentNumber: paymentNumber,
          type: 'payment',
          amount: payment.amount,
          method: payment.method.code,
          paymentDate: payment.paymentDate,
          supplierId: Value(payment.supplierId),
          referenceNumber: Value(payment.referenceNumber),
          notes: Value(payment.notes),
          createdBy: payment.createdBy ?? 1,
        ),
      );

      // 3. Create cash transaction if payment method is cash
      if (payment.method == PaymentMethod.cash) {
        await database.into(database.cashTransactions).insert(
          db.CashTransactionsCompanion.insert(
            amount: payment.amount,
            type: 'out',
            description: 'سند صرف رقم $paymentNumber',
            transactionDate: payment.paymentDate,
            relatedPaymentId: Value(id),
            createdBy: payment.createdBy ?? 1,
          ),
        );
      }

      return id;
    });
  }

  @override
  Future<void> updatePayment(domain.Payment payment) async {
    await (database.update(database.payments)..where((t) => t.id.equals(payment.id!))).write(
      db.PaymentsCompanion(
        amount: Value(payment.amount),
        method: Value(payment.method.code),
        paymentDate: Value(payment.paymentDate),
        referenceNumber: Value(payment.referenceNumber),
        notes: Value(payment.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deletePayment(int id) async {
    await (database.update(database.payments)..where((t) => t.id.equals(id))).write(
      db.PaymentsCompanion(deletedAt: Value(DateTime.now())),
    );
    
    // Also mark related cash transaction as deleted? 
    // In current schema, cashTransactions don't have deletedAt. 
    // We might need to delete it physically or handle it in reports.
  }

  @override
  Future<String> generatePaymentNumber([String type = 'receipt']) async {
    final prefix = type == 'receipt' ? 'REC' : 'PAY';
    final query = database.select(database.payments)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
      ..limit(1);
    
    final lastPayment = await query.getSingleOrNull();
    int nextId = 1;
    
    if (lastPayment != null) {
      final parts = lastPayment.paymentNumber.split('-');
      if (parts.length == 2) {
        nextId = (int.tryParse(parts[1]) ?? 0) + 1;
      }
    }
    
    return '$prefix-${nextId.toString().padLeft(5, '0')}';
  }

  @override
  Future<double> getTotalReceipts({DateTime? fromDate, DateTime? toDate}) async {
    final amount = database.payments.amount.sum();
    final query = database.selectOnly(database.payments)..addColumns([amount]);
    
    query.where(
      database.payments.type.equals('receipt') &
          database.payments.deletedAt.isNull(),
    );
    
    if (fromDate != null) {
      query.where(database.payments.paymentDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.payments.paymentDate.isSmallerOrEqualValue(toDate));
    }
    
    final result = await query.getSingle();
    return result.read(amount) ?? 0.0;
  }

  @override
  Future<double> getTotalPayments({DateTime? fromDate, DateTime? toDate}) async {
    final amount = database.payments.amount.sum();
    final query = database.selectOnly(database.payments)..addColumns([amount]);
    
    query.where(
      database.payments.type.equals('payment') &
          database.payments.deletedAt.isNull(),
    );
    
    if (fromDate != null) {
      query.where(database.payments.paymentDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.payments.paymentDate.isSmallerOrEqualValue(toDate));
    }
    
    final result = await query.getSingle();
    return result.read(amount) ?? 0.0;
  }

  @override
  Future<List<domain.Payment>> getCustomerPayments(int customerId) async {
    return getAllPayments(customerId: customerId, type: 'receipt');
  }

  @override
  Future<List<domain.Payment>> getSupplierPayments(int supplierId) async {
    return getAllPayments(supplierId: supplierId, type: 'payment');
  }

  Stream<List<domain.Payment>> watchAllPayments({String? type}) {
    final query = database.select(database.payments)
      ..where((t) {
      if (type != null) {
        return t.type.equals(type) & t.deletedAt.isNull();
      }
        return t.deletedAt.isNull();
      })
      ..orderBy([(t) => OrderingTerm(expression: t.paymentDate, mode: OrderingMode.desc)]);

    return query.watch().asyncMap((rows) => Future.wait(rows.map(_mapToEntity)));
  }

  Future<domain.Payment> _mapToEntity(db.PaymentTable row) async {
    customer_domain.Customer? customer;
    if (row.customerId != null) {
      final custRow = await (database.select(database.customers)..where((t) => t.id.equals(row.customerId!))).getSingleOrNull();
      if (custRow != null) {
        customer = customer_domain.Customer(
          id: custRow.id,
          name: custRow.name,
          phone: custRow.phone,
          address: custRow.address,
        );
      }
    }

    supplier_domain.Supplier? supplier;
    if (row.supplierId != null) {
      final suppRow = await (database.select(database.suppliers)..where((t) => t.id.equals(row.supplierId!))).getSingleOrNull();
      if (suppRow != null) {
        supplier = supplier_domain.Supplier(
          id: suppRow.id,
          name: suppRow.name,
          phone: suppRow.phone,
          address: suppRow.address,
        );
      }
    }

    return domain.Payment(
      id: row.id,
      paymentNumber: row.paymentNumber,
      type: row.type,
      customerId: row.customerId,
      customer: customer,
      supplierId: row.supplierId,
      supplier: supplier,
      invoiceId: row.invoiceId,
      purchaseInvoiceId: row.purchaseInvoiceId,
      amount: row.amount,
      method: PaymentMethod.fromCode(row.method),
      paymentDate: row.paymentDate,
      referenceNumber: row.referenceNumber,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
