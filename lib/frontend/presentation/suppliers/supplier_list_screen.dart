import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
// import 'package:poultry_accounting/backend/domain/entities/supplier.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ط¥ط¯ط§ط±ط© ط§ظ„ظ…ظˆط±ط¯ظٹظ†'),
        backgroundColor: Colors.green,
      ),
      body: ref.watch(suppliersStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('ظ„ط§ ظٹظˆط¬ط¯ ظ…ظˆط±ط¯ظٹظ† ظ…ط¶ط§ظپظٹظ† ط¨ط¹ط¯'));
          }

          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.business, color: Colors.orange),
                ),
                title: Text(supplier.name),
                subtitle: Text(supplier.phone ?? 'ط¨ط¯ظˆظ† ط±ظ‚ظ… ظ‡ط§طھظپ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupplierFormScreen(supplier: supplier),
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
            MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
