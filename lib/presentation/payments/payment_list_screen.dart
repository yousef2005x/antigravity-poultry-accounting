import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
// import 'package:poultry_accounting/domain/entities/cash_transaction.dart';
import 'payment_form_screen.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المدفوعات والقبض'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildBalanceSummary(ref),
          Expanded(
            child: ref.watch(transactionsStreamProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('خطأ: $err')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('لا يوجد عمليات مسجلة'));
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isIn = tx.type == 'in';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIn ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx.description.isEmpty ? (isIn ? 'قبض' : 'صرف') : tx.description),
                      subtitle: Text('${tx.transactionDate.year}-${tx.transactionDate.month}-${tx.transactionDate.day}'),
                      trailing: Text(
                        '${tx.amount} ₪',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIn ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceSummary(WidgetRef ref) {
    return ref.watch(boxBalanceProvider).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Text('Error: $err'),
      data: (balance) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(bottom: BorderSide(color: Colors.green.shade200)),
        ),
        child: Column(
          children: [
            const Text('رصيد الصندوق الحالي', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '${balance.toStringAsFixed(2)} ₪',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
