/// Report data models and repository interface
library;

/// Dashboard metrics
class DashboardMetrics {
  const DashboardMetrics({
    required this.todaySales,
    required this.todayReceipts,
    required this.todayExpenses,
    required this.todaySalaries,
    required this.todayPurchases,
    required this.totalCustomers,
    required this.totalOutstanding,
    required this.overdueInvoices,
    required this.lowStockProducts,
  });

  final double todaySales;
  final double todayReceipts;
  final double todayExpenses;
  final double todaySalaries;
  final double todayPurchases;
  final int totalCustomers;
  final double totalOutstanding;
  final int overdueInvoices;
  final int lowStockProducts;
}

/// Profit and Loss report
class ProfitLossReport {
  const ProfitLossReport({
    required this.revenue,
    required this.cost,
    required this.expenses,
    required this.salaries,
    required this.annualInventories,
    required this.profit,
    required this.netProfit,
    required this.profitMargin,
  });

  final double revenue;
  final double cost;
  final double expenses; // Operating expenses (no salaries)
  final double salaries;
  final double annualInventories;
  final double profit; // Gross/Operating profit
  final double netProfit; // After salaries and returns
  final double profitMargin;
}

/// Cash flow entry
class CashFlowEntry {
  const CashFlowEntry({
    required this.date,
    required this.description,
    required this.type, // 'in' or 'out'
    required this.amount,
    required this.balance,
  });

  final DateTime date;
  final String description;
  final String type;
  final double amount;
  final double balance;
}

/// Customer statement entry
class CustomerStatementEntry {
  const CustomerStatementEntry({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit, // Customer owes us (Sales)
    required this.credit, // Customer paid us (Receipts)
    required this.balance,
  });

  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final double balance;
}

/// Supplier statement entry
class SupplierStatementEntry {
  const SupplierStatementEntry({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit, // We paid them (Payments)
    required this.credit, // We owe them (Purchases)
    required this.balance,
    this.isPaid = false,
    this.type = 'purchase', // 'purchase', 'payment', 'opening'
  });

  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final double balance;
  final bool isPaid;
  final String type;
}

/// Aging report entry
class AgingReportEntry {
  const AgingReportEntry({
    required this.customerId,
    required this.customerName,
    required this.current,
    required this.days30,
    required this.days60,
    required this.days90,
    required this.over90,
    required this.total,
  });

  final int customerId;
  final String customerName;
  final double current; // 0-30 days
  final double days30; // 31-60 days
  final double days60; // 61-90 days
  final double days90; // 90+ days
  final double over90;
  final double total;
}

/// Daily Processing statistics
class ProcessingReport {
  const ProcessingReport({
    required this.totalLiveWeight,
    required this.totalSlaughteredWeight,
    required this.totalOutputWeight,
    required this.shrinkageWeight,
    required this.processingCount,
  });

  final double totalLiveWeight;
  final double totalSlaughteredWeight;
  final double totalOutputWeight;
  final double shrinkageWeight;
  final int processingCount;
}

/// Daily Sales statistics
class SalesSummary {
  const SalesSummary({
    required this.totalAmount,
    required this.invoiceCount,
    required this.totalWeightSold,
    required this.productBreakdown,
  });

  final double totalAmount;
  final int invoiceCount;
  final double totalWeightSold;
  final List<Map<String, dynamic>> productBreakdown;
}

/// Comprehensive Daily Report
class DailyReport {
  const DailyReport({
    required this.date,
    required this.processing,
    required this.sales,
    required this.expenses,
    required this.salaries,
    required this.netCashFlow,
  });

  final DateTime date;
  final ProcessingReport processing;
  final SalesSummary sales;
  final double expenses;
  final double salaries;
  final double netCashFlow;
}

/// Report Repository Interface
abstract class ReportRepository {
  /// Get dashboard metrics
  Future<DashboardMetrics> getDashboardMetrics();

  /// Get profit and loss report
  Future<ProfitLossReport> getProfitLossReport({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get aging report (customer outstanding balances by age)
  Future<List<AgingReportEntry>> getAgingReport();

  /// Get sales report by period
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get top customers by sales
  Future<List<Map<String, dynamic>>> getTopCustomers({
    int limit = 10,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get product sales report
  Future<List<Map<String, dynamic>>> getProductSalesReport({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get cash flow report
  Future<List<CashFlowEntry>> getCashFlowReport({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get customer account statement
  Future<List<CustomerStatementEntry>> getCustomerStatement(
    int customerId, {
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get supplier account statement
  Future<List<SupplierStatementEntry>> getSupplierStatement(
    int supplierId, {
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get annual inventories (adjustments)
  Future<double> getTotalAnnualInventories({
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Get comprehensive daily report
  Future<DailyReport> getDailyReport(DateTime date);

  /// Get inventory age report
  Future<List<InventoryAgeEntry>> getInventoryAgeReport();
}

/// Inventory age entry
class InventoryAgeEntry {
  const InventoryAgeEntry({
    required this.productName,
    required this.quantity,
    required this.entryDate,
    required this.ageInDays,
  });

  final String productName;
  final double quantity;
  final DateTime entryDate;
  final int ageInDays;
}
