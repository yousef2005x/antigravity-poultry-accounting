import 'package:poultry_accounting/domain/entities/customer.dart';

/// Customer Repository Interface
abstract class CustomerRepository {
  /// Get all customers (excluding deleted)
  Future<List<Customer>> getAllCustomers();

  /// Watch all customers (excluding deleted)
  Stream<List<Customer>> watchAllCustomers();

  /// Get customer by ID
  Future<Customer?> getCustomerById(int id);

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query);

  /// Get active customers only
  Future<List<Customer>> getActiveCustomers();

  /// Create new customer
  Future<int> createCustomer(Customer customer);

  /// Update existing customer
  Future<void> updateCustomer(Customer customer);

  /// Soft delete customer
  Future<void> deleteCustomer(int id);

  /// Get customer balance (total outstanding)
  Future<double> getCustomerBalance(int customerId);

  /// Get customer statement (invoices and payments)
  Future<Map<String, dynamic>> getCustomerStatement(
    int customerId, {
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get customer aging report
  Future<Map<String, double>> getCustomerAging(int customerId);

  /// Check if customer exceeds credit limit
  Future<bool> isCreditLimitExceeded(int customerId);
}
