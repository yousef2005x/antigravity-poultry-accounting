import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';

class CreditNotesScreen extends ConsumerWidget {
  const CreditNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات الدائنة'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(creditNotesProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('لا يوجد إشعارات دائنة بعد'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final dateFormat = DateFormat('yyyy/MM/dd');
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(note.creditNoteNumber),
                  subtitle: Text('${dateFormat.format(note.creditNoteDate)} | الفاتورة المرجعية: ${note.originalInvoiceId}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'القيمة: ${note.amount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        note.docstatus == 1 ? 'معتمد' : 'مسودة',
                        style: TextStyle(
                          color: note.docstatus == 1 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show details
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('تفاصيل الإشعار الدائن: ${note.creditNoteNumber}'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('السبب: ${note.reason ?? "غير محدد"}'),
                            const SizedBox(height: 8),
                            Text('النوع المرجعي: ${note.originalInvoiceType}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إغلاق'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سيتم إضافة إنشاء إشعار دائن لاحقاً')),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
