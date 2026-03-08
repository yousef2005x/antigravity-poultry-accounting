import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الميزانية العمومية'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(balanceSheetProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (balanceSheet) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('الأصول', Colors.green),
                _buildAccountsList(balanceSheet.assets),
                _buildTotalRow('إجمالي الأصول', balanceSheet.totalAssets, Colors.green),
                
                const Divider(height: 32, thickness: 2),
                
                _buildSectionTitle('الخصوم', Colors.red),
                _buildAccountsList(balanceSheet.liabilities),
                _buildTotalRow('إجمالي الخصوم', balanceSheet.totalLiabilities, Colors.red),
                
                const Divider(height: 32, thickness: 2),
                
                _buildSectionTitle('حقوق الملكية', Colors.blue),
                _buildAccountsList(balanceSheet.equity),
                _buildTotalRow('إجمالي حقوق الملكية', balanceSheet.totalEquity, Colors.blue),
                
                const Divider(height: 32, thickness: 2),
                
                Card(
                  color: Colors.blueGrey.shade50,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTotalRow(
                          'إجمالي الخصوم وحقوق الملكية', 
                          balanceSheet.totalLiabilities + balanceSheet.totalEquity, 
                          Colors.black87
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('الميزانية متزنة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(
                              (balanceSheet.totalAssets - (balanceSheet.totalLiabilities + balanceSheet.totalEquity)).abs() < 0.01 
                                ? Icons.check_circle : Icons.warning,
                              color: (balanceSheet.totalAssets - (balanceSheet.totalLiabilities + balanceSheet.totalEquity)).abs() < 0.01 
                                ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildAccountsList(List<dynamic> accounts) {
    if (accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('لا يوجد حسابات'),
      );
    }
    
    return Column(
      children: accounts.map((account) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${account.accountCode} - ${account.accountName}'),
              Text(
                account.balance.abs().toStringAsFixed(2),
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
}
