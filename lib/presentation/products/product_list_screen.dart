import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'product_form_screen.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأصناف والمنتجات'),
        backgroundColor: Colors.green,
      ),
      body: ref.watch(productsStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('لا توجد أصناف مضافة بعد'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.egg, color: Colors.green),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('الوحدة: ${product.unitType.name} | السعر الافتراضي: ${product.defaultPrice} ₪'),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
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
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
