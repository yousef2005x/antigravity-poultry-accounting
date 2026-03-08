import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'annual_inventory_form_screen.dart';

class AnnualInventoriesScreen extends ConsumerWidget {
  const AnnualInventoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الجرد السنوي (تسويات الأرباح)'),
        backgroundColor: Colors.indigo,
      ),
      body: ref.watch(annualInventoriesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (inventories) {
              if (inventories.isEmpty) {
                return const Center(child: Text('لا توجد تسويات جرد مسجلة'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: inventories.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = inventories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade400,
                      child: const Icon(Icons.inventory, color: Colors.white),
                    ),
                    title: Text(
                      item.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'التاريخ: ${item.inventoryDate.day}/${item.inventoryDate.month}/${item.inventoryDate.year}',
                    ),
                    trailing: Text(
                      '${item.amount.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnualInventoryFormScreen(annualInventory: item),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnualInventoryFormScreen()),
        ),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
