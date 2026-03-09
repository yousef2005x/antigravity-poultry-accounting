import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/repositories/report_repository.dart';

class CentralDebtRegisterScreen extends ConsumerStatefulWidget {
  const CentralDebtRegisterScreen({super.key});

  @override
  ConsumerState<CentralDebtRegisterScreen> createState() => _CentralDebtRegisterScreenState();
}

class _CentralDebtRegisterScreenState extends ConsumerState<CentralDebtRegisterScreen> {
  bool _isLoading = true;
  List<AgingReportEntry> _customerDebts = [];
  List<Map<String, dynamic>> _supplierDebts = [];

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    setState(() => _isLoading = true);
    try {
      final reportRepo = ref.read(reportRepositoryProvider);
      
      // Fetch customer debts using aging report logic (cached/reused)
      final customers = await reportRepo.getAgingReport();
      
      // Fetch supplier debts logic manually for now or implement in repo
      // Ideally should be in repo
      final suppliers = await _fetchSupplierBalances();

      setState(() {
        _customerDebts = customers;
        _supplierDebts = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSupplierBalances() async {
    // This is a simplified version. For a production app, this should be in ReportRepository.
    final reportRepo = ref.read(reportRepositoryProvider);
    final supplierRepo = ref.read(supplierRepositoryProvider);
    final allSuppliers = await supplierRepo.getAllSuppliers();
    
    final List<Map<String, dynamic>> balances = [];
    for (final s in allSuppliers) {
      final statement = await reportRepo.getSupplierStatement(s.id!);
      if (statement.isNotEmpty && statement.last.balance > 0.1) {
        balances.add({
          'id': s.id,
          'name': s.name,
          'balance': statement.last.balance,
        });
      }
    }
    return balances;
  }

  double get _totalCustomerDebt => _customerDebts.fold(0, (sum, e) => sum + e.total);
  double get _totalSupplierDebt => _supplierDebts.fold(0, (sum, e) => sum + (e['balance'] as double));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الديون الموحد'),
          backgroundColor: Colors.blueGrey,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'ديون العملاء (لنا)', icon: Icon(Icons.group_outlined)),
              Tab(text: 'ديون الموردين (علينا)', icon: Icon(Icons.local_shipping_outlined)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCustomerDebtsTab(),
                  _buildSupplierDebtsTab(),
                ],
              ),
        bottomNavigationBar: _buildTotalSummary(),
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي مديونية العملاء', _totalCustomerDebt, Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem('إجمالي مستحقات الموردين', _totalSupplierDebt, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(2)} ₪',
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCustomerDebtsTab() {
    if (_customerDebts.isEmpty) {
      return const Center(child: Text('لا توجد ديون عملاء حالياً'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _customerDebts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final debt = _customerDebts[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(debt.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            '${debt.total.toStringAsFixed(2)} ₪',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildSupplierDebtsTab() {
    if (_supplierDebts.isEmpty) {
      return const Center(child: Text('لا توجد مديونية لموردين حالياً'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _supplierDebts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final debt = _supplierDebts[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
          title: Text(debt['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            '${(debt['balance'] as double).toStringAsFixed(2)} ₪',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }
}
