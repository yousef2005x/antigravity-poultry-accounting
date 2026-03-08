import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/frontend/presentation/reports/customer_statement_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ط§ظ„طھظ‚ط§ط±ظٹط± ط§ظ„طھط­ظ„ظٹظ„ظٹط©'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'ط§ظ„ط£ط±ط¨ط§ط­ ظˆط§ظ„ط®ط³ط§ط¦ط±'),
            Tab(text: 'ظ…ط¨ظٹط¹ط§طھ ط§ظ„ط£طµظ†ط§ظپ'),
            Tab(text: 'ط£ط¹ظ…ط§ط± ط§ظ„ط°ظ…ظ…'),
            Tab(text: 'ط­ط±ظƒط© ط§ظ„طµظ†ط¯ظˆظ‚'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProfitLossTab(),
          ProductSalesReportTab(),
          AgingReportTab(),
          CashFlowTab(),
        ],
      ),
    );
  }
}

class ProductSalesReportTab extends ConsumerWidget {
  const ProductSalesReportTab({super.key});

  Future<void> _exportToPdf(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');

      final pdfData = await ref.read(pdfServiceProvider).generateProductSalesPdf(
            salesData: data,
            companyName: companyName,
            companyPhone: companyPhone,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'product_sales_report.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ طھطµط¯ظٹط± PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(productSalesStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'طھط­ظ„ظٹظ„ ظ…ط¨ظٹط¹ط§طھ ط§ظ„ط£طµظ†ط§ظپ (ط§ظ„ط£ط¹ظ„ظ‰ ظ…ط¨ظٹط¹ط§ظ‹)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              reportAsync.whenOrNull(
                data: (data) => data.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.purple),
                        tooltip: 'طھطµط¯ظٹط± PDF',
                        onPressed: () => _exportToPdf(context, ref, data),
                      )
                    : null,
              ) ?? const SizedBox.shrink(),
            ],
          ),
        ),
        Expanded(
          child: reportAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ظ…ط¨ظٹط¹ط§طھ ظ…ط³ط¬ظ„ط©'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ط§ظ„طµظ†ظپ')),
                    DataColumn(label: Text('ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط¨ط§ط¹ط©'), numeric: true),
                    DataColumn(label: Text('ط§ظ„ط¥ظٹط±ط§ط¯ط§طھ'), numeric: true),
                    DataColumn(label: Text('ط§ظ„ط£ط±ط¨ط§ط­'), numeric: true),
                  ],
                  rows: data.map((row) {
                    return DataRow(cells: [
                      DataCell(Text(row['productName'] ?? '')),
                      DataCell(Text(row['totalQuantity'].toStringAsFixed(1))),
                      DataCell(Text('${row['totalRevenue'].toStringAsFixed(2)} ط´ظٹظƒظ„')),
                      DataCell(Text(
                        '${row['profit'].toStringAsFixed(2)} ط´ظٹظƒظ„',
                        style: TextStyle(
                          color: (row['profit'] as double) >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),),
                    ],);
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
          ),
        ),
      ],
    );
  }
}

class AgingReportTab extends ConsumerWidget {
  const AgingReportTab({super.key});

  Future<void> _exportToPdf(BuildContext context, WidgetRef ref, List<AgingReportEntry> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');

      final pdfData = await ref.read(pdfServiceProvider).generateAgingReportPdf(
            entries: data,
            companyName: companyName,
            companyPhone: companyPhone,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'aging_report.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ طھطµط¯ظٹط± PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(agingReportStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ط£ط¹ظ…ط§ط± ط°ظ…ظ… ط§ظ„ط¹ظ…ظ„ط§ط، (ط¨ط§ظ„ط£ظٹط§ظ…)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              reportAsync.whenOrNull(
                data: (data) => data.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.amber),
                        tooltip: 'طھطµط¯ظٹط± PDF',
                        onPressed: () => _exportToPdf(context, ref, data),
                      )
                    : null,
              ) ?? const SizedBox.shrink(),
            ],
          ),
        ),
        Expanded(
          child: reportAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ط°ظ…ظ… ظ…ط³طھط­ظ‚ط©'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ط§ظ„ط¹ظ…ظٹظ„')),
                    DataColumn(label: Text('ط­ط§ظ„ظٹط§ظ‹'), numeric: true), // 0-30
                    DataColumn(label: Text('30-60 ظٹظˆظ…'), numeric: true),
                    DataColumn(label: Text('60-90 ظٹظˆظ…'), numeric: true),
                    DataColumn(label: Text('>90 ظٹظˆظ…'), numeric: true),
                    DataColumn(label: Text('ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ'), numeric: true),
                    DataColumn(label: Text('ط¥ط¬ط±ط§ط،')),
                  ],
                  rows: data.map((entry) {
                    return DataRow(cells: [
                      DataCell(Text(entry.customerName)),
                      DataCell(Text(entry.current > 0 ? entry.current.toStringAsFixed(2) : '-')),
                      DataCell(Text(entry.days30 > 0 ? entry.days30.toStringAsFixed(2) : '-')),
                      DataCell(Text(entry.days60 > 0 ? entry.days60.toStringAsFixed(2) : '-')),
                      DataCell(Text((entry.days90 + entry.over90) > 0 
                          ? (entry.days90 + entry.over90).toStringAsFixed(2) 
                          : '-',),), // Combine 90+ buckets for simpler view if wanted, or split
                      DataCell(Text(
                        entry.total.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),),
                      DataCell(IconButton(
                        icon: const Icon(Icons.receipt_long, color: Colors.blue),
                        onPressed: () {
                          // We need to pass a Customer object or just the ID.
                          // But CustomerStatementScreen needs a Customer object currently.
                          // We can fetch it or just pass the ID and name.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerStatementScreen(
                                customer: Customer(
                                  id: entry.customerId,
                                  name: entry.customerName,
                                ),
                              ),
                            ),
                          );
                        },
                      ),),
                    ],);
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
          ),
        ),
      ],
    );
  }
}

class ProfitLossTab extends ConsumerWidget {
  const ProfitLossTab({super.key});

  Future<void> _exportToPdf(BuildContext context, WidgetRef ref, ProfitLossReport data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');

      final pdfData = await ref.read(pdfServiceProvider).generateProfitLossPdf(
            report: data,
            companyName: companyName,
            companyPhone: companyPhone,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'profit_loss_report.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ طھطµط¯ظٹط± PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(profitLossStreamProvider);

    return reportAsync.when(
      data: (data) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                  tooltip: 'طھطµط¯ظٹط± PDF',
                  onPressed: () => _exportToPdf(context, ref, data),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMetricCard('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط¥ظٹط±ط§ط¯ط§طھ', data.revenue, Colors.green),
                  const SizedBox(height: 12),
                  _buildMetricCard('طھظƒظ„ظپط© ط§ظ„ط¨ط¶ط§ط¹ط© ط§ظ„ظ…ط¨ط§ط¹ط©', data.cost, Colors.orange),
                  const SizedBox(height: 12),
                  _buildMetricCard('ط§ظ„ظ…طµط±ظˆظپط§طھ ط§ظ„طھط´ط؛ظٹظ„ظٹط©', data.expenses, Colors.red),
                  const Divider(height: 16),
                  _buildMetricCard('ط§ظ„ط±ط¨ط­ ط§ظ„طھط´ط؛ظٹظ„ظٹ', data.profit, Colors.blue, isBold: true),
                  const SizedBox(height: 16),
                  _buildMetricCard('ط§ظ„ط±ظˆط§طھط¨ ظˆط§ظ„ط£ط¬ظˆط±', data.salaries, Colors.teal),
                  const SizedBox(height: 12),
                  _buildMetricCard('ط§ظ„ط¬ط±ط¯ ط§ظ„ط³ظ†ظˆظٹ / طھط³ظˆظٹط©', data.annualInventories, Colors.indigo),
                  const Divider(height: 32),
                  _buildMetricCard(
                    'طµط§ظپظٹ ط§ظ„ط±ط¨ط­ ط§ظ„ظ†ظ‡ط§ط¦ظٹ',
                    data.netProfit,
                    data.netProfit >= 0 ? Colors.green.shade700 : Colors.red,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ظ‡ط§ظ…ط´ ط§ظ„ط±ط¨ط­ ط§ظ„ظ†ظ‡ط§ط¦ظٹ: ${data.profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: data.netProfit >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
    );
  }

  Widget _buildMetricCard(String title, double value, Color color, {bool isBold = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            Text(
              '${value.toStringAsFixed(2)} ط´ظٹظƒظ„',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CashFlowTab extends ConsumerWidget {
  const CashFlowTab({super.key});

  Future<void> _exportToPdf(BuildContext context, WidgetRef ref, List<CashFlowEntry> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');

      final pdfData = await ref.read(pdfServiceProvider).generateCashFlowPdf(
            entries: data,
            companyName: companyName,
            companyPhone: companyPhone,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'cash_flow_report.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ طھطµط¯ظٹط± PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(cashFlowStreamProvider);

    return reportAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ط­ط±ظƒط© ظپظٹ ط§ظ„طµظ†ط¯ظˆظ‚'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.teal),
                    tooltip: 'طھطµط¯ظٹط± PDF',
                    onPressed: () => _exportToPdf(context, ref, data),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = data[index];
                  final isOpening = entry.type == 'opening';
                  final isIn = entry.type == 'in' || entry.type == 'receipt';

                  return ListTile(
                    leading: Icon(
                      isOpening ? Icons.account_balance : (isIn ? Icons.arrow_downward : Icons.arrow_upward),
                      color: isOpening ? Colors.grey : (isIn ? Colors.green : Colors.red),
                    ),
                    title: Text(entry.description),
                    subtitle: Text('${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isOpening)
                          Text(
                            '${isIn ? "+" : "-"}${entry.amount.toStringAsFixed(2)} ط´ظٹظƒظ„',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIn ? Colors.green : Colors.red,
                            ),
                          ),
                        Text(
                          'ط§ظ„ط±طµظٹط¯: ${entry.balance.toStringAsFixed(2)} ط´ظٹظƒظ„',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
    );
  }
}

// Simple providers for reports (move to database_providers.dart later if needed)
final profitLossStreamProvider = FutureProvider<ProfitLossReport>((ref) async {
  return ref.read(reportRepositoryProvider).getProfitLossReport();
});

final productSalesStreamProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(reportRepositoryProvider).getProductSalesReport();
});

final agingReportStreamProvider = FutureProvider<List<AgingReportEntry>>((ref) async {
  return ref.read(reportRepositoryProvider).getAgingReport();
});

final cashFlowStreamProvider = FutureProvider<List<CashFlowEntry>>((ref) async {
  return ref.read(reportRepositoryProvider).getCashFlowReport();
});
