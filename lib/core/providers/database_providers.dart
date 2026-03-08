import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/backend/data/database/database.dart';
import 'package:poultry_accounting/backend/data/repositories/repositories.dart';
import 'package:poultry_accounting/backend/domain/entities/annual_inventory.dart';
import 'package:poultry_accounting/backend/domain/entities/cash_transaction.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/entities/expense.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';
import 'package:poultry_accounting/backend/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/salary.dart';
import 'package:poultry_accounting/backend/domain/entities/supplier.dart';
import 'package:poultry_accounting/backend/domain/repositories/annual_inventory_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/backup_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/customer_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/expense_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/i_cash_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/i_partner_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/i_price_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/i_processing_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/invoice_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/product_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/purchase_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/salary_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/supplier_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/user_repository.dart';
import 'package:poultry_accounting/backend/domain/repositories/payment_repository.dart';
import 'package:poultry_accounting/backend/domain/entities/payment.dart' as domain;
import 'package:poultry_accounting/backend/domain/repositories/stock_conversion_repository.dart';
import 'package:poultry_accounting/backend/data/repositories/stock_conversion_repository_impl.dart';

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

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UserRepositoryImpl(db);
});

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SalaryRepositoryImpl(db);
});

final annualInventoryRepositoryProvider = Provider<AnnualInventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AnnualInventoryRepositoryImpl(db);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentRepositoryImpl(db);
});

final stockConversionRepositoryProvider = Provider<StockConversionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return StockConversionRepositoryImpl(db);
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

final salariesStreamProvider = StreamProvider<List<Salary>>((ref) {
  final repo = ref.read(salaryRepositoryProvider);
  return repo.watchAllSalaries();
});

final paymentsStreamProvider = StreamProvider<List<domain.Payment>>((ref) {
  final repo = ref.read(paymentRepositoryProvider) as PaymentRepositoryImpl;
  return repo.watchAllPayments();
});

final annualInventoriesStreamProvider = StreamProvider<List<AnnualInventory>>((ref) {
  final repo = ref.read(annualInventoryRepositoryProvider);
  return repo.watchAllInventories();
});

final boxBalanceProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.getBalance();
});

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  // Watch relevant streams to trigger a refresh when data changes
  ref.watch(invoicesStreamProvider);
  ref.watch(paymentsStreamProvider);
  ref.watch(expensesStreamProvider);
  ref.watch(salariesStreamProvider);
  ref.watch(purchasesStreamProvider);
  ref.watch(customersStreamProvider);
  
  return ref.read(reportRepositoryProvider).getDashboardMetrics();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ReportRepositoryImpl(database);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl();
});
