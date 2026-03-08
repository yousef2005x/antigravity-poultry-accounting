import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';

class IncomeStatementScreen extends ConsumerStatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  ConsumerState<IncomeStatementScreen> createState() => _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends ConsumerState<IncomeStatementScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // The provider takes a formatted string or DateRange params.
    // Assuming the provider expects ISO strings:
    final providerParams = (
      startDate: _startDate.toIso8601String(), 
      endDate: _endDate.toIso8601String()
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الدخل'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: ref.watch(incomeStatementProvider(providerParams)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (incomeStatement) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateRangeIndicator(),
                const SizedBox(height: 16),
                
                _buildSectionTitle('الإيرادات', Colors.green),
                _buildAccountsList(incomeStatement.revenue),
                _buildTotalRow('إجمالي الإيرادات', incomeStatement.totalRevenue, Colors.green),
                
                const Divider(height: 32, thickness: 2),
                
                _buildSectionTitle('المصروفات', Colors.red),
                _buildAccountsList(incomeStatement.expenses),
                _buildTotalRow('إجمالي المصروفات', incomeStatement.totalExpenses, Colors.red),
                
                const Divider(height: 32, thickness: 2),
                
                Card(
                  color: incomeStatement.netIncome >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTotalRow(
                      incomeStatement.netIncome >= 0 ? 'صافي الربح' : 'صافي الخسارة', 
                      incomeStatement.netIncome.abs(), 
                      incomeStatement.netIncome >= 0 ? Colors.green.shade800 : Colors.red.shade800
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'من: ${_startDate.year}/${_startDate.month}/${_startDate.day}  إلى: ${_endDate.year}/${_endDate.month}/${_endDate.day}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<dynamic> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('لا يوجد بيانات'),
      );
    }
    
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${row.accountCode} - ${row.accountName}'),
              Text(
                row.amount.abs().toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(
            amount.abs().toStringAsFixed(2),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
