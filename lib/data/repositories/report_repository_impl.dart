import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this.database);

  final AppDatabase database;

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    // Basic implementation for now
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // Today's Sales
    final salesQuery = database.selectOnly(database.salesInvoices)
      ..addColumns([database.salesInvoices.total.sum()])
      ..where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(startOfDay));
    final todaySales = await salesQuery.map((row) => row.read(database.salesInvoices.total.sum())).getSingle() ?? 0.0;

    // Today's Receipts (Cash In)
    final receiptsQuery = database.selectOnly(database.cashTransactions)
      ..addColumns([database.cashTransactions.amount.sum()])
      ..where(database.cashTransactions.transactionDate.isBiggerOrEqualValue(startOfDay))
      ..where(database.cashTransactions.type.equals('receipt'));
      
    final todayReceipts = await receiptsQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;

    // Today's Expenses
    final expensesQuery = database.selectOnly(database.expenses)
      ..addColumns([database.expenses.amount.sum()])
      ..where(database.expenses.expenseDate.isBiggerOrEqualValue(startOfDay));
      
    final todayExpenses = await expensesQuery.map((row) => row.read(database.expenses.amount.sum())).getSingle() ?? 0.0;

    // Total Customers
    final customersCount = await database.select(database.customers).get().then((l) => l.length);

    // Total Outstanding (Sum of Customer Balances)
    final allSalesTotalQuery = database.selectOnly(database.salesInvoices)
      ..addColumns([database.salesInvoices.total.sum()])
      ..where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.name));
      
    final allSalesTotal = await allSalesTotalQuery.map((row) => row.read(database.salesInvoices.total.sum())).getSingle() ?? 0.0;
      
    final allReceiptsTotalQuery = database.selectOnly(database.cashTransactions)
      ..addColumns([database.cashTransactions.amount.sum()])
      ..where(database.cashTransactions.type.equals('receipt'));
      
    final allReceiptsTotal = await allReceiptsTotalQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;
      
    final totalOutstanding = allSalesTotal - allReceiptsTotal;

    // Low Stock Products
    final batches = await database.select(database.inventoryBatches).get();
    final productStocks = <int, double>{};
    for (final b in batches) {
      productStocks[b.productId] = (productStocks[b.productId] ?? 0) + b.remainingQuantity;
    }
    final lowStockCount = productStocks.values.where((q) => q <= 5).length; // Threshold 5

    return DashboardMetrics(
      todaySales: todaySales,
      todayReceipts: todayReceipts,
      todayExpenses: todayExpenses,
      totalCustomers: customersCount,
      totalOutstanding: totalOutstanding,
      overdueInvoices: 0, // Placeholder
      lowStockProducts: lowStockCount,
    );
  }

  @override
  Future<ProfitLossReport> getProfitLossReport({DateTime? fromDate, DateTime? toDate}) async {
    // 1. Revenue: Sales Invoices Subtotal (excluding tax for pure revenue, or total if simple)
    // Let's use Total - Tax for Revenue if we want Net Revenue. Or just Total.
    // Standard: Revenue = Sales.
    final revenueQuery = database.selectOnly(database.salesInvoices)
      ..addColumns([database.salesInvoices.total.sum()])
      ..where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code));
    
    if (fromDate != null) {
      revenueQuery.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      revenueQuery.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    
    final revenue = await revenueQuery.map((row) => row.read(database.salesInvoices.total.sum())).getSingle() ?? 0.0;

    // 2. Cost of Goods Sold (COGS)
    // We need to join SalesInvoiceItems with SalesInvoices to filter by date/status
    final cogsQuery = database.selectOnly(database.salesInvoiceItems)
      ..join([
        innerJoin(database.salesInvoices, database.salesInvoices.id.equalsExp(database.salesInvoiceItems.invoiceId)),
      ])
      ..addColumns([
        (database.salesInvoiceItems.costAtSale * database.salesInvoiceItems.quantity).sum(),
      ])
      ..where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.name));

    if (fromDate != null) {
      cogsQuery.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      cogsQuery.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }

    final cogs = await cogsQuery.map((row) => row.read((database.salesInvoiceItems.costAtSale * database.salesInvoiceItems.quantity).sum())).getSingle() ?? 0.0;

    // 3. Expenses
    final expensesQuery = database.selectOnly(database.expenses)
      ..addColumns([database.expenses.amount.sum()]);
      
    if (fromDate != null) {
      expensesQuery.where(database.expenses.expenseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      expensesQuery.where(database.expenses.expenseDate.isSmallerOrEqualValue(toDate));
    }

    final expenses = await expensesQuery.map((row) => row.read(database.expenses.amount.sum())).getSingle() ?? 0.0;

    // 4. Calculate Net Profit
    final profit = revenue - cogs - expenses;
    final profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

    return ProfitLossReport(
      revenue: revenue,
      cost: cogs,
      expenses: expenses,
      profit: profit,
      profitMargin: profitMargin,
    );
  }

  @override
  Future<List<AgingReportEntry>> getAgingReport() async {
    final customers = await database.select(database.customers).get();
    final List<AgingReportEntry> report = [];

    for (final customer in customers) {
      if (!customer.isActive) {
        continue;
      }

      // 1. Get all confirmed invoices for this customer, sorted by date (oldest first)
      final invoicesQuery = database.select(database.salesInvoices)
        ..where((tbl) => tbl.customerId.equals(customer.id))
        ..where((tbl) => tbl.status.equals(InvoiceStatus.confirmed.name))
        ..orderBy([(t) => OrderingTerm(expression: t.invoiceDate)]);
      
      final invoices = await invoicesQuery.get();
      if (invoices.isEmpty) {
        continue;
      }

      // 2. Get total receipts for this customer
      final receiptsQuery = database.selectOnly(database.payments)
        ..addColumns([database.payments.amount.sum()])
        ..where(database.payments.customerId.equals(customer.id))
        ..where(database.payments.type.equals('receipt')); // Receipts reduce debt
      
      final totalPaid = await receiptsQuery.map((row) => row.read(database.payments.amount.sum())).getSingle() ?? 0.0;
      
      double remainingPayment = totalPaid;
      double current = 0;
      double days30 = 0;
      double days60 = 0;
      double days90 = 0;
      double over90 = 0;
      double totalOutstanding = 0;

      // 3. FIFO Allocation: Pay off oldest invoices first
      for (final invoice in invoices) {
        final double invoiceAmount = invoice.total;
        
        if (remainingPayment >= invoiceAmount) {
          // Fully paid
          remainingPayment -= invoiceAmount;
        } else {
          // Partially paid or unpaid
          final double outstandingOnInvoice = invoiceAmount - remainingPayment;
          remainingPayment = 0; // All payments used up

          // Categorize by age
          final age = DateTime.now().difference(invoice.invoiceDate).inDays;
          
          if (age <= 30) {
            current += outstandingOnInvoice;
          } else if (age <= 60) {
            days30 += outstandingOnInvoice;
          } else if (age <= 90) {
            days60 += outstandingOnInvoice;
          } else if (age <= 120) {
            days90 += outstandingOnInvoice;
          } else {
            over90 += outstandingOnInvoice;
          }

          totalOutstanding += outstandingOnInvoice;
        }
      }

      if (totalOutstanding > 0.01) { // Ignore tiny float errors
        report.add(AgingReportEntry(
          customerId: customer.id,
          customerName: customer.name,
          current: current,
          days30: days30,
          days60: days60,
          days90: days90,
          over90: over90,
          total: totalOutstanding,
        ),);
      }
    }

    return report;
  }

  @override
  Future<Map<String, dynamic>> getSalesReport({DateTime? fromDate, DateTime? toDate}) async {
    return {}; // TODO: Implement
  }

  @override
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10, DateTime? fromDate, DateTime? toDate}) async {
    return []; // TODO: Implement
  }

  @override
  Future<List<Map<String, dynamic>>> getProductSalesReport({DateTime? fromDate, DateTime? toDate}) async {
    final query = database.select(database.salesInvoiceItems)
      .join([
        innerJoin(database.salesInvoices, database.salesInvoices.id.equalsExp(database.salesInvoiceItems.invoiceId)),
        innerJoin(database.products, database.products.id.equalsExp(database.salesInvoiceItems.productId)),
      ]);

    query.where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.name));

    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }

    final rows = await query.get();

    // Group by product and aggregate
    final Map<int, Map<String, dynamic>> productStats = {};

    for (final row in rows) {
      final item = row.readTable(database.salesInvoiceItems);
      final product = row.readTable(database.products);

      if (!productStats.containsKey(product.id)) {
        productStats[product.id] = {
          'productName': product.name,
          'totalQuantity': 0.0,
          'totalRevenue': 0.0,
          'totalCost': 0.0,
        };
      }

      final stats = productStats[product.id]!;
      stats['totalQuantity'] = (stats['totalQuantity'] as double) + item.quantity;
      stats['totalRevenue'] = (stats['totalRevenue'] as double) + item.total;
      stats['totalCost'] = (stats['totalCost'] as double) + (item.costAtSale * item.quantity);
    }

    // Calculate profit for each product
    final result = productStats.values.map((stats) {
      final revenue = stats['totalRevenue'] as double;
      final cost = stats['totalCost'] as double;
      return {
        ...stats,
        'profit': revenue - cost,
      };
    }).toList();

    // Sort by revenue descending
    result.sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));

    return result;
  }
}
