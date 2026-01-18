import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';

/// Invoice Repository Interface
abstract class InvoiceRepository {
  /// Get all sales invoices
  Future<List<Invoice>> getAllInvoices({
    InvoiceStatus? status,
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Watch all sales invoices
  Stream<List<Invoice>> watchAllInvoices({
    InvoiceStatus? status,
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get invoice by ID
  Future<Invoice?> getInvoiceById(int id);

  /// Get invoice by invoice number
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber);

  /// Create new draft invoice
  Future<int> createInvoice(Invoice invoice);

  /// Update draft invoice
  Future<void> updateInvoice(Invoice invoice);

  /// Confirm invoice (finalizes it, prevents editing)
  Future<void> confirmInvoice(int invoiceId, int userId);

  /// Cancel invoice
  Future<void> cancelInvoice(int invoiceId, int userId);

  /// Soft delete invoice
  Future<void> deleteInvoice(int id);

  /// Generate next invoice number
  Future<String> generateInvoiceNumber();

  /// Get invoice total revenue
  Future<double> getTotalRevenue({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get invoice total profit
  Future<double> getTotalProfit({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get unpaid invoices for customer
  Future<List<Invoice>> getUnpaidInvoices(int customerId);

  /// Update paid amount for invoice
  Future<void> updatePaidAmount(int invoiceId, double amount);
}
