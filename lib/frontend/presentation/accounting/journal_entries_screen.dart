import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';
import 'package:poultry_accounting/backend/domain/entities/journal_entry.dart';

class JournalEntriesScreen extends ConsumerWidget {
  const JournalEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القيود اليومية'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(journalEntriesStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('لا يوجد قيود يومية بعد'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
              
              double totalDebit = 0;
              for (final line in entry.lines) {
                totalDebit += line.debitAmount;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.entryNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'الإجمالي: ${totalDebit.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Text('${dateFormat.format(entry.entryDate)} - ${entry.description}'),
                  children: entry.lines.map((line) {
                    return ListTile(
                      title: Text(line.accountName ?? 'حساب غير معروف'),
                      subtitle: Text(line.description ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (line.debitAmount > 0)
                            Text('مدين: ${line.debitAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                          if (line.creditAmount > 0)
                            Text('دائن: ${line.creditAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('القيود اليدوية سيتم إضافتها قريباً')),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
