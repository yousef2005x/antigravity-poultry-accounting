import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'purchase_form_screen.dart';

class PurchaseListScreen extends ConsumerWidget {
  const PurchaseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المشتريات'),
        backgroundColor: Colors.blueGrey,
      ),
      body: ref.watch(purchasesStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (purchases) {
          if (purchases.isEmpty) {
            return const Center(child: Text('لا توجد فواتير مشتريات مسجلة'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final invoice = purchases[index];
              final isConfirmed = invoice.status == InvoiceStatus.confirmed;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isConfirmed ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Icon(
                    Icons.shopping_cart,
                    color: isConfirmed ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  'فاتورة رقم: ${invoice.invoiceNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المورد: ${invoice.supplier?.name ?? 'تحميل...'}'),
                    Text('التاريخ: ${invoice.invoiceDate.year}-${invoice.invoiceDate.month}-${invoice.invoiceDate.day}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${invoice.total.toStringAsFixed(2)} ₪',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      invoice.statusDisplayName,
                      style: TextStyle(
                        color: isConfirmed ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PurchaseFormScreen(invoice: invoice),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
          );
        },
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add),
      ),
    );
  }
}
