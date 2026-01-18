import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/purchase_invoice.dart';

abstract class PurchaseRepository {
  Future<List<PurchaseInvoice>> getAllPurchaseInvoices({
    InvoiceStatus? status,
    int? supplierId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Stream<List<PurchaseInvoice>> watchAllPurchaseInvoices();

  Future<PurchaseInvoice?> getPurchaseInvoiceById(int id);

  Future<int> createPurchaseInvoice(PurchaseInvoice invoice);

  Future<void> updatePurchaseInvoice(PurchaseInvoice invoice);

  Future<void> confirmPurchaseInvoice(int invoiceId, int userId);

  Future<void> deletePurchaseInvoice(int id);

  Future<String> generatePurchaseInvoiceNumber();

  Future<double> getTotalPurchases({DateTime? fromDate, DateTime? toDate});
}
