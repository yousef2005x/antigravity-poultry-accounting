import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/customer.dart' as domain;
import 'package:poultry_accounting/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {

  CustomerRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<domain.Customer>> getAllCustomers() async {
    final rows = await database.select(database.customers).get();
    return rows.map(_mapToEntity).toList().cast<domain.Customer>();
  }

  @override
  Stream<List<domain.Customer>> watchAllCustomers() {
    return database.select(database.customers).watch().map((rows) => rows.map(_mapToEntity).toList().cast<domain.Customer>());
  }

  @override
  Future<domain.Customer?> getCustomerById(int id) async {
    final query = database.select(database.customers)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createCustomer(domain.Customer customer) {
    return database.into(database.customers).insert(
      db.CustomersCompanion.insert(
        name: customer.name,
        phone: Value(customer.phone),
        address: Value(customer.address),
        creditLimit: Value(customer.creditLimit),
        notes: Value(customer.notes),
      ),
    );
  }

  @override
  Future<void> updateCustomer(domain.Customer customer) async {
    await (database.update(database.customers)..where((t) => t.id.equals(customer.id!))).write(
      db.CustomersCompanion(
        name: Value(customer.name),
        phone: Value(customer.phone),
        address: Value(customer.address),
        creditLimit: Value(customer.creditLimit),
        notes: Value(customer.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await (database.update(database.customers)..where((t) => t.id.equals(id))).write(
      db.CustomersCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<List<domain.Customer>> getActiveCustomers() async {
    final query = database.select(database.customers)..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapToEntity).toList().cast<domain.Customer>();
  }

  @override
  Future<List<domain.Customer>> searchCustomers(String query) async {
    final results = await (database.select(database.customers)..where((t) => t.name.like('%$query%') | t.phone.like('%$query%'))).get();
    return results.map(_mapToEntity).toList().cast<domain.Customer>();
  }

  @override
  Future<double> getCustomerBalance(int customerId) async {
    // Basic implementation: Confirmed Invoices - Paid Amount
    final query = database.select(database.salesInvoices)
      ..where((t) => t.customerId.equals(customerId) & t.status.equals('confirmed'));
    final invoices = await query.get();
    double balance = 0;
    for (final inv in invoices) {
      balance += inv.total - inv.paidAmount;
    }
    return balance;
  }

  @override
  Future<Map<String, dynamic>> getCustomerStatement(int customerId, {DateTime? fromDate, DateTime? toDate}) async {
    return {}; // Placeholder
  }

  @override
  Future<Map<String, double>> getCustomerAging(int customerId) async {
    return {}; // Placeholder
  }

  @override
  Future<bool> isCreditLimitExceeded(int customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      return false;
    }
    final balance = await getCustomerBalance(customerId);
    return balance > customer.creditLimit;
  }

  domain.Customer _mapToEntity(db.CustomerTable row) {
    return domain.Customer(
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
}
