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
      
    // Today's Salaries
    final salariesQuery = database.selectOnly(database.salaries)
      ..addColumns([database.salaries.amount.sum()])
      ..where(database.salaries.salaryDate.isBiggerOrEqualValue(startOfDay));
      
    final todaySalaries = await salariesQuery.map((row) => row.read(database.salaries.amount.sum())).getSingle() ?? 0.0;
    
    // Today's Purchases
    final purchasesQuery = database.selectOnly(database.purchaseInvoices)
      ..addColumns([database.purchaseInvoices.total.sum()])
      ..where(database.purchaseInvoices.invoiceDate.isBiggerOrEqualValue(startOfDay));
      
    final todayPurchases = await purchasesQuery.map((row) => row.read(database.purchaseInvoices.total.sum())).getSingle() ?? 0.0;

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

    // Overdue Invoices (not fully paid after 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final overdueQuery = database.selectOnly(database.salesInvoices)
      ..addColumns([database.salesInvoices.id.count()])
      ..where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code))
      ..where(database.salesInvoices.invoiceDate.isSmallerThanValue(thirtyDaysAgo))
      ..where(database.salesInvoices.total.isBiggerThan(database.salesInvoices.paidAmount));
    
    final overdueCount = await overdueQuery.map((row) => row.read(database.salesInvoices.id.count())).getSingle() ?? 0;

    return DashboardMetrics(
      todaySales: todaySales,
      todayReceipts: todayReceipts,
      todayExpenses: todayExpenses,
      todaySalaries: todaySalaries,
      todayPurchases: todayPurchases,
      totalCustomers: customersCount,
      totalOutstanding: totalOutstanding,
      overdueInvoices: overdueCount,
      lowStockProducts: lowStockCount,
    );
  }

  @override
  Future<double> getTotalAnnualInventories({DateTime? fromDate, DateTime? toDate}) async {
    final amountExp = database.annualInventories.amount.sum();
    final query = database.selectOnly(database.annualInventories)..addColumns([amountExp]);

    if (fromDate != null) {
      query.where(database.annualInventories.inventoryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.annualInventories.inventoryDate.isSmallerOrEqualValue(toDate));
    }

    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
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

    // 4. Salaries
    final salariesQuery = database.selectOnly(database.salaries)
      ..addColumns([database.salaries.amount.sum()]);
    if (fromDate != null) {
      salariesQuery.where(database.salaries.salaryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      salariesQuery.where(database.salaries.salaryDate.isSmallerOrEqualValue(toDate));
    }
    final salaries =
        await salariesQuery.map((row) => row.read(database.salaries.amount.sum())).getSingle() ?? 0.0;

    // 5. Annual Inventories (Adjustments)
    final returnsQuery = database.selectOnly(database.annualInventories)
      ..addColumns([database.annualInventories.amount.sum()]);
    if (fromDate != null) {
      returnsQuery.where(database.annualInventories.inventoryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      returnsQuery.where(database.annualInventories.inventoryDate.isSmallerOrEqualValue(toDate));
    }
    final annualInventories =
        await returnsQuery.map((row) => row.read(database.annualInventories.amount.sum())).getSingle() ?? 0.0;

    // 6. Calculate Profits
    final profit = revenue - cogs - expenses;
    final netProfit = profit - salaries - annualInventories;
    final profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;

    return ProfitLossReport(
      revenue: revenue,
      cost: cogs,
      expenses: expenses,
      salaries: salaries,
      annualInventories: annualInventories,
      profit: profit,
      netProfit: netProfit,
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
    final report = await getProductSalesReport(fromDate: fromDate, toDate: toDate);
    
    double totalRevenue = 0;
    double totalProfit = 0;
    double totalQty = 0;
    
    for (final item in report) {
      totalRevenue += item['totalRevenue'] as double;
      totalProfit += item['profit'] as double;
      totalQty += item['totalQuantity'] as double;
    }
    
    return {
      'revenue': totalRevenue,
      'profit': totalProfit,
      'quantity': totalQty,
      'itemsCount': report.length,
      'details': report,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10, DateTime? fromDate, DateTime? toDate}) async {
    final query = database.select(database.salesInvoices).join([
      innerJoin(database.customers, database.customers.id.equalsExp(database.salesInvoices.customerId)),
    ]);

    query.where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code));
    if (fromDate != null) {
      query.where(database.salesInvoices.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salesInvoices.invoiceDate.isSmallerOrEqualValue(toDate));
    }

    final results = await query.get();
    final Map<int, Map<String, dynamic>> customerStats = {};

    for (final row in results) {
      final invoice = row.readTable(database.salesInvoices);
      final customer = row.readTable(database.customers);

      if (!customerStats.containsKey(customer.id)) {
        customerStats[customer.id] = {
          'id': customer.id,
          'name': customer.name,
          'totalSales': 0.0,
          'invoiceCount': 0,
        };
      }

      final stats = customerStats[customer.id]!;
      stats['totalSales'] = (stats['totalSales'] as double) + invoice.total;
      stats['invoiceCount'] = (stats['invoiceCount'] as int) + 1;
    }

    final sortedList = customerStats.values.toList()
      ..sort((a, b) => (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return sortedList.take(limit).toList();
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

  @override
  Future<List<CashFlowEntry>> getCashFlowReport({DateTime? fromDate, DateTime? toDate}) async {
    final query = database.select(database.cashTransactions)..orderBy([(t) => OrderingTerm(expression: t.transactionDate)]);
    
    // For cash flow, we usually need the starting balance before fromDate
    double balance = 0;
    if (fromDate != null) {
      final openingBalanceQuery = database.selectOnly(database.cashTransactions)
        ..addColumns([database.cashTransactions.amount.sum()])
        ..where(database.cashTransactions.transactionDate.isSmallerThanValue(fromDate))
        ..where(database.cashTransactions.type.equals('in'));
      final totalIn = await openingBalanceQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;

      final openingBalanceOutQuery = database.selectOnly(database.cashTransactions)
        ..addColumns([database.cashTransactions.amount.sum()])
        ..where(database.cashTransactions.transactionDate.isSmallerThanValue(fromDate))
        ..where(database.cashTransactions.type.equals('out'));
      final totalOut = await openingBalanceOutQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;
      
      balance = totalIn - totalOut;
    }

    if (fromDate != null) {
      query.where((tbl) => tbl.transactionDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((tbl) => tbl.transactionDate.isSmallerOrEqualValue(toDate));
    }

    final transactions = await query.get();
    final List<CashFlowEntry> report = [];

    // Add opening balance entry if fromDate is set
    if (fromDate != null) {
      report.add(CashFlowEntry(
        date: fromDate,
        description: 'رصيد سابق',
        type: 'opening',
        amount: 0,
        balance: balance,
      ),);
    }

    for (final tx in transactions) {
      if (tx.type == 'in' || tx.type == 'receipt') {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
      report.add(CashFlowEntry(
        date: tx.transactionDate,
        description: tx.description,
        type: tx.type,
        amount: tx.amount,
        balance: balance,
      ),);
    }

    return report;
  }

  @override
  Future<List<CustomerStatementEntry>> getCustomerStatement(int customerId, {DateTime? fromDate, DateTime? toDate}) async {
    final List<CustomerStatementEntry> entries = [];
    double balance = 0;

    // 1. Calculate opening balance if fromDate is provided
    if (fromDate != null) {
      final salesQuery = database.selectOnly(database.salesInvoices)
        ..addColumns([database.salesInvoices.total.sum()])
        ..where(database.salesInvoices.customerId.equals(customerId))
        ..where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code))
        ..where(database.salesInvoices.invoiceDate.isSmallerThanValue(fromDate));
      final totalSales = await salesQuery.map((row) => row.read(database.salesInvoices.total.sum())).getSingle() ?? 0.0;

      final receiptsQuery = database.selectOnly(database.payments)
        ..addColumns([database.payments.amount.sum()])
        ..where(database.payments.customerId.equals(customerId))
        ..where(database.payments.type.equals('receipt'))
        ..where(database.payments.paymentDate.isSmallerThanValue(fromDate));
      final totalReceipts = await receiptsQuery.map((row) => row.read(database.payments.amount.sum())).getSingle() ?? 0.0;
      
      balance = totalSales - totalReceipts;
      
      entries.add(CustomerStatementEntry(
        date: fromDate,
        description: 'رصيد سابق',
        reference: '-',
        debit: 0,
        credit: 0,
        balance: balance,
      ),);
    }

    // 2. Fetch Sales Invoices
    final salesQuery = database.select(database.salesInvoices)
      ..where((tbl) => tbl.customerId.equals(customerId))
      ..where((tbl) => tbl.status.equals(InvoiceStatus.confirmed.code));
    if (fromDate != null) {
      salesQuery.where((tbl) => tbl.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      salesQuery.where((tbl) => tbl.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    final sales = await salesQuery.get();

    // 3. Fetch Receipts
    final receiptsQuery = database.select(database.payments)
      ..where((tbl) => tbl.customerId.equals(customerId))
      ..where((tbl) => tbl.type.equals('receipt'));
    if (fromDate != null) {
      receiptsQuery.where((tbl) => tbl.paymentDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      receiptsQuery.where((tbl) => tbl.paymentDate.isSmallerOrEqualValue(toDate));
    }
    final receipts = await receiptsQuery.get();

    // 4. Merge and sort
    final List<dynamic> transactions = [...sales, ...receipts];
    transactions.sort((a, b) {
      final dateA = a is SalesInvoiceTable ? a.invoiceDate : (a as PaymentTable).paymentDate;
      final dateB = b is SalesInvoiceTable ? b.invoiceDate : (b as PaymentTable).paymentDate;
      return dateA.compareTo(dateB);
    });

    // 5. Build statement
    for (final tx in transactions) {
      if (tx is SalesInvoiceTable) {
        // Fetch items for this invoice to include in description
        final itemsQuery = database.select(database.salesInvoiceItems).join([
          innerJoin(database.products, database.products.id.equalsExp(database.salesInvoiceItems.productId)),
        ])..where(database.salesInvoiceItems.invoiceId.equals(tx.id));
        
        final items = await itemsQuery.get();
        final itemsDesc = items.map((row) {
          final item = row.readTable(database.salesInvoiceItems);
          final prod = row.readTable(database.products);
          return '${prod.name} (${item.quantity} كغ)';
        }).join('، ');

        balance += tx.total;
        entries.add(CustomerStatementEntry(
          date: tx.invoiceDate,
          description: 'فاتورة مبيعات: $itemsDesc',
          reference: tx.invoiceNumber,
          debit: tx.total,
          credit: 0,
          balance: balance,
        ),);
      } else if (tx is PaymentTable) {
        final method = PaymentMethod.fromCode(tx.method);
        balance -= tx.amount;
        entries.add(CustomerStatementEntry(
          date: tx.paymentDate,
          description: 'سند قبض - ${method.nameAr}${tx.notes != null ? ' (${tx.notes})' : ''}',
          reference: tx.paymentNumber,
          debit: 0,
          credit: tx.amount,
          balance: balance,
        ),);
      }
    }

    return entries;
  }

  @override
  Future<List<SupplierStatementEntry>> getSupplierStatement(int supplierId, {DateTime? fromDate, DateTime? toDate}) async {
    final List<SupplierStatementEntry> entries = [];
    double balance = 0;

    // 1. Calculate opening balance if fromDate is provided
    if (fromDate != null) {
      final purchaseQuery = database.selectOnly(database.purchaseInvoices)
        ..addColumns([database.purchaseInvoices.total.sum()])
        ..where(database.purchaseInvoices.supplierId.equals(supplierId))
        ..where(database.purchaseInvoices.status.equals(InvoiceStatus.confirmed.code))
        ..where(database.purchaseInvoices.invoiceDate.isSmallerThanValue(fromDate));
      final totalPurchases = await purchaseQuery.map((row) => row.read(database.purchaseInvoices.total.sum())).getSingle() ?? 0.0;

      final paymentsQuery = database.selectOnly(database.payments)
        ..addColumns([database.payments.amount.sum()])
        ..where(database.payments.supplierId.equals(supplierId))
        ..where(database.payments.type.equals('payment'))
        ..where(database.payments.paymentDate.isSmallerThanValue(fromDate));
      final totalPayments = await paymentsQuery.map((row) => row.read(database.payments.amount.sum())).getSingle() ?? 0.0;
      
      balance = totalPurchases - totalPayments;
      
      entries.add(SupplierStatementEntry(
        date: fromDate,
        description: 'رصيد سابق',
        reference: '-',
        debit: 0,
        credit: 0,
        balance: balance,
        type: 'opening',
      ),);
    }

    // 2. Fetch Purchase Invoices
    final purchaseQuery = database.select(database.purchaseInvoices)
      ..where((tbl) => tbl.supplierId.equals(supplierId))
      ..where((tbl) => tbl.status.equals(InvoiceStatus.confirmed.code));
    if (fromDate != null) {
      purchaseQuery.where((tbl) => tbl.invoiceDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      purchaseQuery.where((tbl) => tbl.invoiceDate.isSmallerOrEqualValue(toDate));
    }
    final purchases = await purchaseQuery.get();

    // 3. Fetch Payments
    final paymentsQuery = database.select(database.payments)
      ..where((tbl) => tbl.supplierId.equals(supplierId))
      ..where((tbl) => tbl.type.equals('payment'));
    if (fromDate != null) {
      paymentsQuery.where((tbl) => tbl.paymentDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      paymentsQuery.where((tbl) => tbl.paymentDate.isSmallerOrEqualValue(toDate));
    }
    final payments = await paymentsQuery.get();

    // 4. Merge and sort
    final List<dynamic> transactions = [...purchases, ...payments];
    transactions.sort((a, b) {
      final dateA = a is PurchaseInvoiceTable ? a.invoiceDate : (a as PaymentTable).paymentDate;
      final dateB = b is PurchaseInvoiceTable ? b.invoiceDate : (b as PaymentTable).paymentDate;
      return dateA.compareTo(dateB);
    });

    // 5. Build statement
    for (final tx in transactions) {
      if (tx is PurchaseInvoiceTable) {
        balance += tx.total;
        entries.add(SupplierStatementEntry(
          date: tx.invoiceDate,
          description: 'فاتورة مشتريات #${tx.invoiceNumber}',
          reference: tx.invoiceNumber,
          debit: 0,
          credit: tx.total,
          balance: balance,
          isPaid: tx.paidAmount >= tx.total,
        ),);
      } else if (tx is PaymentTable) {
        final method = PaymentMethod.fromCode(tx.method);
        balance -= tx.amount;
        entries.add(SupplierStatementEntry(
          date: tx.paymentDate,
          description: 'سند صرف - ${method.nameAr}${tx.notes != null ? ' (${tx.notes})' : ''}',
          reference: tx.paymentNumber,
          debit: tx.amount,
          credit: 0,
          balance: balance,
          type: 'payment',
        ),);
      }
    }

    return entries;
  }

  @override
  Future<DailyReport> getDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    // 1. Processing Report
    final procQuery = database.select(database.rawMeatProcessings)
      ..where((tbl) => tbl.processingDate.isBetweenValues(startOfDay, endOfDay));
    final processes = await procQuery.get();

    double totalLive = 0, totalSlaughtered = 0, totalOutput = 0, shrinkage = 0;
    for (final p in processes) {
      totalLive += p.liveNetWeight;
      totalSlaughtered += p.slaughteredNetWeight;
      shrinkage += (p.liveNetWeight - p.slaughteredNetWeight).clamp(0, double.infinity);
    }

    final outputsQuery = database.select(database.processingOutputs).join([
      innerJoin(database.rawMeatProcessings, database.rawMeatProcessings.id.equalsExp(database.processingOutputs.processingId)),
    ])..where(database.rawMeatProcessings.processingDate.isBetweenValues(startOfDay, endOfDay));
    
    final outputRows = await outputsQuery.get();
    for (final row in outputRows) {
      totalOutput += row.readTable(database.processingOutputs).quantity;
    }

    final processingReport = ProcessingReport(
      totalLiveWeight: totalLive,
      totalSlaughteredWeight: totalSlaughtered,
      totalOutputWeight: totalOutput,
      shrinkageWeight: shrinkage,
      processingCount: processes.length,
    );

    // 2. Sales Summary
    final salesQuery = database.select(database.salesInvoices)
      ..where((tbl) => tbl.invoiceDate.isBetweenValues(startOfDay, endOfDay))
      ..where((tbl) => tbl.status.equals(InvoiceStatus.confirmed.name));
    final invoices = await salesQuery.get();

    double totalSalesAmount = 0, totalWeightSold = 0;
    final Map<int, Map<String, dynamic>> productBreakdownMap = {};

    for (final inv in invoices) {
      totalSalesAmount += inv.total;
      
      final items = await (database.select(database.salesInvoiceItems).join([
        innerJoin(database.products, database.products.id.equalsExp(database.salesInvoiceItems.productId)),
      ])..where(database.salesInvoiceItems.invoiceId.equals(inv.id))).get();

      for (final item in items) {
        final qty = item.readTable(database.salesInvoiceItems).quantity;
        final prod = item.readTable(database.products);
        totalWeightSold += qty;

        if (!productBreakdownMap.containsKey(prod.id)) {
          productBreakdownMap[prod.id] = {
            'productId': prod.id,
            'productName': prod.name,
            'quantity': 0.0,
            'amount': 0.0,
          };
        }
        productBreakdownMap[prod.id]!['quantity'] += qty;
        productBreakdownMap[prod.id]!['amount'] += item.readTable(database.salesInvoiceItems).total;
      }
    }

    final salesSummary = SalesSummary(
      totalAmount: totalSalesAmount,
      invoiceCount: invoices.length,
      totalWeightSold: totalWeightSold,
      productBreakdown: productBreakdownMap.values.toList(),
    );

    // 3. Expenses
    final expQuery = database.selectOnly(database.expenses)
      ..addColumns([database.expenses.amount.sum()])
      ..where(database.expenses.expenseDate.isBetweenValues(startOfDay, endOfDay));
    final totalExpenses = await expQuery.map((row) => row.read(database.expenses.amount.sum())).getSingle() ?? 0.0;

    // 4. Salaries
    final salaryQuery = database.selectOnly(database.salaries)
      ..addColumns([database.salaries.amount.sum()])
      ..where(database.salaries.salaryDate.isBetweenValues(startOfDay, endOfDay));
    final totalSalariesDaily = await salaryQuery.map((row) => row.read(database.salaries.amount.sum())).getSingle() ?? 0.0;

    // 5. Net Cash Flow
    final receiptsQuery = database.selectOnly(database.cashTransactions)
      ..addColumns([database.cashTransactions.amount.sum()])
      ..where(database.cashTransactions.transactionDate.isBetweenValues(startOfDay, endOfDay))
      ..where(database.cashTransactions.type.isIn(['in', 'receipt']));
    final totalIn = await receiptsQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;

    final outQuery = database.selectOnly(database.cashTransactions)
      ..addColumns([database.cashTransactions.amount.sum()])
      ..where(database.cashTransactions.transactionDate.isBetweenValues(startOfDay, endOfDay))
      ..where(database.cashTransactions.type.isIn(['out', 'payment']));
    final totalOutDirect = await outQuery.map((row) => row.read(database.cashTransactions.amount.sum())).getSingle() ?? 0.0;

    return DailyReport(
      date: date,
      processing: processingReport,
      sales: salesSummary,
      expenses: totalExpenses,
      salaries: totalSalariesDaily,
      netCashFlow: totalIn - totalOutDirect - totalExpenses - totalSalariesDaily,
    );
  }

  @override
  Future<List<InventoryAgeEntry>> getInventoryAgeReport() async {
    final now = DateTime.now();
    final query = database.select(database.inventoryBatches).join([
      innerJoin(database.products, database.products.id.equalsExp(database.inventoryBatches.productId)),
    ])..where(database.inventoryBatches.remainingQuantity.isBiggerThanValue(0))
      ..orderBy([OrderingTerm(expression: database.inventoryBatches.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      final batch = row.readTable(database.inventoryBatches);
      final product = row.readTable(database.products);
      final entryDate = batch.createdAt;
      final age = now.difference(entryDate).inDays;

      return InventoryAgeEntry(
        productName: product.name,
        quantity: batch.remainingQuantity,
        entryDate: entryDate,
        ageInDays: age,
      );
    }).toList();
  }
}
