import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';

class TrialBalanceScreen extends ConsumerWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ميزان المراجعة'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(trialBalanceProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('لا يوجد بيانات لميزان المراجعة'));
          }

          double totalDebit = 0;
          double totalCredit = 0;
          
          for (final row in rows) {
            totalDebit += row.balance > 0 ? row.balance : 0;
            totalCredit += row.balance < 0 ? row.balance.abs() : 0;
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('رقم الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: rows.map((row) {
                        return DataRow(cells: [
                          DataCell(Text(row.accountCode)),
                          DataCell(Text(row.accountName)),
                          DataCell(Text(row.balance > 0 ? row.balance.toStringAsFixed(2) : '-')),
                          DataCell(Text(row.balance < 0 ? row.balance.abs().toStringAsFixed(2) : '-')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('مدين: ${totalDebit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('دائن: ${totalCredit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Icon(
                      (totalDebit - totalCredit).abs() < 0.01 ? Icons.check_circle : Icons.warning,
                      color: (totalDebit - totalCredit).abs() < 0.01 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
