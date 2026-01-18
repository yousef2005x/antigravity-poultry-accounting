/// Report data models and repository interface
library;

/// Dashboard metrics
class DashboardMetrics {
  const DashboardMetrics({
    required this.todaySales,
    required this.todayReceipts,
    required this.todayExpenses,
    required this.totalCustomers,
    required this.totalOutstanding,
    required this.overdueInvoices,
    required this.lowStockProducts,
  });

  final double todaySales;
  final double todayReceipts;
  final double todayExpenses;
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
    required this.profit,
    required this.profitMargin,
  });

  final double revenue;
  final double cost;
  final double expenses;
  final double profit;
  final double profitMargin;
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
}
