import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/data/database/database.dart';
import 'package:poultry_accounting/data/repositories/repositories.dart';
import 'package:poultry_accounting/domain/entities/cash_transaction.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/expense.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/repositories/backup_repository.dart';
import 'package:poultry_accounting/domain/repositories/customer_repository.dart';
import 'package:poultry_accounting/domain/repositories/expense_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_cash_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_partner_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_price_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_processing_repository.dart';
import 'package:poultry_accounting/domain/repositories/invoice_repository.dart';
import 'package:poultry_accounting/domain/repositories/product_repository.dart';
import 'package:poultry_accounting/domain/repositories/purchase_repository.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/domain/repositories/supplier_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final processingRepositoryProvider = Provider<IProcessingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProcessingRepositoryImpl(db);
});

final priceRepositoryProvider = Provider<IPriceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductPriceRepositoryImpl(db);
});

final partnerRepositoryProvider = Provider<IPartnerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PartnerRepositoryImpl(db);
});

final cashRepositoryProvider = Provider<ICashRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CashRepositoryImpl(db);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceRepositoryImpl(db);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepositoryImpl(db);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepositoryImpl(db);
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SupplierRepositoryImpl(db);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PurchaseRepositoryImpl(db);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(db);
});

// Stream Providers for real-time updates
final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchAllCustomers();
});

final suppliersStreamProvider = StreamProvider<List<Supplier>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchAllSuppliers();
});

final transactionsStreamProvider = StreamProvider<List<CashTransaction>>((ref) {
  final repo = ref.read(cashRepositoryProvider);
  return repo.watchAllTransactions();
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.read(productRepositoryProvider);
  return repo.watchAllProducts();
});

final purchasesStreamProvider = StreamProvider<List<PurchaseInvoice>>((ref) {
  final repo = ref.read(purchaseRepositoryProvider);
  return repo.watchAllPurchaseInvoices();
});

final expenseCategoriesStreamProvider = StreamProvider<List<ExpenseCategory>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.watchAllCategories();
});

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.watchAllExpenses();
});

final invoicesStreamProvider = StreamProvider<List<Invoice>>((ref) {
  final repo = ref.read(invoiceRepositoryProvider);
  return repo.watchAllInvoices();
});

final boxBalanceProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.getBalance();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ReportRepositoryImpl(database);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});
