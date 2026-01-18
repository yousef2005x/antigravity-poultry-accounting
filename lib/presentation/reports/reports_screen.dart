import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('التقارير التحليلية'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'مبيعات الأصناف'),
            Tab(text: 'أعمار الذمم'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductSalesReportTab(),
          AgingReportTab(),
        ],
      ),
    );
  }
}

class ProductSalesReportTab extends ConsumerWidget {
  const ProductSalesReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(productSalesStreamProvider);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'تحليل مبيعات الأصناف (الأعلى مبيعاً)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: reportAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('لا توجد مبيعات مسجلة'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الصنف')),
                    DataColumn(label: Text('الكمية المباعة'), numeric: true),
                    DataColumn(label: Text('الإيرادات'), numeric: true),
                    DataColumn(label: Text('الأرباح'), numeric: true),
                  ],
                  rows: data.map((row) {
                    return DataRow(cells: [
                      DataCell(Text(row['productName'] ?? '')),
                      DataCell(Text(row['totalQuantity'].toStringAsFixed(1))),
                      DataCell(Text('${row['totalRevenue'].toStringAsFixed(2)} ₪')),
                      DataCell(Text(
                        '${row['profit'].toStringAsFixed(2)} ₪',
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
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }
}

class AgingReportTab extends ConsumerWidget {
  const AgingReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(agingReportStreamProvider);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'أعمار ذمم العملاء (بالأيام)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: reportAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('لا توجد ذمم مستحقة'));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('العميل')),
                    DataColumn(label: Text('حالياً'), numeric: true), // 0-30
                    DataColumn(label: Text('30-60 يوم'), numeric: true),
                    DataColumn(label: Text('60-90 يوم'), numeric: true),
                    DataColumn(label: Text('>90 يوم'), numeric: true),
                    DataColumn(label: Text('الإجمالي'), numeric: true),
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
                    ],);
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }
}

// Simple providers for reports (move to database_providers.dart later if needed)
final productSalesStreamProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(reportRepositoryProvider).getProductSalesReport();
});

final agingReportStreamProvider = FutureProvider<List<AgingReportEntry>>((ref) async {
  return ref.read(reportRepositoryProvider).getAgingReport();
});
