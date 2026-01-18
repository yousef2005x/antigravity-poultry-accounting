import 'package:poultry_accounting/domain/entities/payment.dart';

/// Payment Repository Interface
abstract class PaymentRepository {
  /// Get all payments (receipts and payments)
  Future<List<Payment>> getAllPayments({
    String? type, // 'receipt' or 'payment'
    int? customerId,
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get payment by ID
  Future<Payment?> getPaymentById(int id);

  /// Get payment by payment number
  Future<Payment?> getPaymentByNumber(String paymentNumber);

  /// Create new receipt (from customer)
  Future<int> createReceipt(Payment payment);

  /// Create new payment (to supplier)
  Future<int> createPayment(Payment payment);

  /// Update payment
  Future<void> updatePayment(Payment payment);

  /// Soft delete payment
  Future<void> deletePayment(int id);

  /// Generate next payment number
  Future<String> generatePaymentNumber();

  /// Get total receipts
  Future<double> getTotalReceipts({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get total payments
  Future<double> getTotalPayments({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get customer payments (receipts)
  Future<List<Payment>> getCustomerPayments(int customerId);

  /// Get supplier payments
  Future<List<Payment>> getSupplierPayments(int supplierId);
}
