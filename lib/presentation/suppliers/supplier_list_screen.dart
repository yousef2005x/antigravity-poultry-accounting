import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
// import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموردين'),
        backgroundColor: Colors.green,
      ),
      body: ref.watch(suppliersStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('لا يوجد موردين مضافين بعد'));
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
                subtitle: Text(supplier.phone ?? 'بدون رقم هاتف'),
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
