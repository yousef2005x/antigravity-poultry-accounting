import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/data/repositories/employee_repository_impl.dart';
import 'package:poultry_accounting/domain/entities/employee.dart';
import 'package:poultry_accounting/domain/entities/salary.dart';
import 'package:poultry_accounting/presentation/salaries/salary_form_screen.dart';

class SalaryStatementScreen extends ConsumerStatefulWidget {
  const SalaryStatementScreen({super.key});

  @override
  ConsumerState<SalaryStatementScreen> createState() => _SalaryStatementScreenState();
}

class _SalaryStatementScreenState extends ConsumerState<SalaryStatementScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month); 
  }

  Future<void> _printStatement(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');

      final pdfData = await ref.read(pdfServiceProvider).generateSalaryStatementPdf(
        month: _selectedMonth,
        salaryData: data,
        companyName: companyName,
        companyPhone: companyPhone,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'salary_statement_${_selectedMonth.month}_${_selectedMonth.year}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الطباعة: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _prepareData(List<Employee> employees, List<Salary> allSalaries) {
    // Filter salaries for selected month (simple filtering)
    final monthlySalaries = allSalaries.where((s) {
      return s.salaryDate.year == _selectedMonth.year && 
             s.salaryDate.month == _selectedMonth.month;
    }).toList();

    return employees.map((emp) {
      final empPayments = monthlySalaries.where((s) {
        if (s.employeeId != null) return s.employeeId == emp.id;
        return s.employeeName == emp.name;
      }).toList();

      final paidSum = empPayments.fold(0.0, (sum, s) => sum + s.amount);
      final remaining = emp.monthlySalary - paidSum;

      return {
        'name': emp.name,
        'fixed': emp.monthlySalary,
        'paid': paidSum,
        'remaining': remaining,
        'payments': empPayments,
        'employee': emp,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final salariesAsync = ref.watch(salariesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف رواتب الموظفين'),
        backgroundColor: Colors.teal,
        actions: [
          employeesAsync.when(
            data: (employees) => salariesAsync.when(
              data: (salaries) => IconButton(
                icon: const Icon(Icons.print),
                onPressed: () {
                  final data = _prepareData(employees, salaries);
                  _printStatement(data);
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: employeesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('خطأ في تحميل الموظفين: $e')),
              data: (employees) {
                return salariesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('خطأ في تحميل الرواتب: $e')),
                  data: (salaries) {
                    final data = _prepareData(employees, salaries);
                    return _buildSalaryTable(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    final dateFormat = intl.DateFormat('MMMM yyyy', 'ar');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.teal.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          const SizedBox(width: 20),
          Text(
            dateFormat.format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('لا يوجد موظفين مسجلين.'));
    }

    double totalFixed = 0;
    double totalPaid = 0;
    double totalRemaining = 0;

    for (final row in data) {
      totalFixed += row['fixed'] as double;
      totalPaid += row['paid'] as double;
      totalRemaining += row['remaining'] as double;
    }

    return Column(
      children: [
        // Grand Totals
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('إجمالي الرواتب', totalFixed, Colors.blue),
              _buildSummaryColumn('المدفوع', totalPaid, Colors.green),
              _buildSummaryColumn('المتبقي', totalRemaining, Colors.red),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 2),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final row = data[index];
              return _buildEmployeeCard(
                row['employee'] as Employee,
                row['paid'] as double,
                row['remaining'] as double,
                row['payments'] as List<Salary>,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          '${value.toStringAsFixed(0)} شيكل',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee emp, double paid, double remaining, List<Salary> payments) {
    final isFullyPaid = remaining <= 0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isFullyPaid ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            isFullyPaid ? Icons.check : Icons.access_time, 
            color: isFullyPaid ? Colors.green : Colors.orange
          ),
        ),
        title: Text(
          emp.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              _buildMiniInfo('الثابت', emp.monthlySalary),
              const SizedBox(width: 16),
              _buildMiniInfo('المدفوع', paid, color: Colors.green),
              const SizedBox(width: 16),
              _buildMiniInfo('المتبقي', remaining, color: remaining > 0 ? Colors.red : Colors.grey),
            ],
          ),
        ),
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('سجل الدفعات هذا الشهر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const Text('لا توجد دفعات', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...payments.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${p.salaryDate.day}/${p.salaryDate.month}', style: const TextStyle(fontSize: 12)),
                        Text('${p.amount.toStringAsFixed(2)} شيكل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => SalaryFormScreen(
                       salary: Salary(
                         amount: 0, 
                         salaryDate: DateTime.now(),
                         employeeName: emp.name,
                         employeeId: emp.id,
                       )
                     )));
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('صرف دفعة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, double value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          '${value.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? Colors.black87),
        ),
      ],
    );
  }
}
