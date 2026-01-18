import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/product.dart';

class StockDashboardScreen extends ConsumerWidget {
  const StockDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المخزون'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Product>>(
        future: _fetchProductsWithStock(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('لا يوجد أصناف متوفرة'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isLowStock = product.currentStock <= 10; // Simple threshold

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLowStock ? 'مخزون منخفض' : 'متوفر',
                              style: TextStyle(
                                color: isLowStock ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          _buildStockInfo('الكمية الحالية', '${product.currentStock} ${product.unitDisplayName}', Icons.inventory),
                          const VerticalDivider(),
                          _buildStockInfo('متوسط التكلفة', '${product.averageCost.toStringAsFixed(2)} ₪', Icons.monetization_on),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'القيمة الإجمالية للمخزون: ${(product.currentStock * product.averageCost).toStringAsFixed(2)} ₪',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<List<Product>> _fetchProductsWithStock(WidgetRef ref) async {
    final repo = ref.read(productRepositoryProvider);
    final products = await repo.getActiveProducts();
    final List<Product> result = [];
    for (final p in products) {
      final withStock = await repo.getProductWithStock(p.id!);
      result.add(withStock);
    }
    return result;
  }
}
