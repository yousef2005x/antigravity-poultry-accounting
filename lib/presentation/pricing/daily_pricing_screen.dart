import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/product_price.dart';

class DailyPricingScreen extends ConsumerStatefulWidget {
  const DailyPricingScreen({super.key});

  @override
  ConsumerState<DailyPricingScreen> createState() => _DailyPricingScreenState();
}

class _DailyPricingScreenState extends ConsumerState<DailyPricingScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Wait for a frame to ensure ref is usable if needed, 
    // but here we just trigger the load after products are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrices();
    });
  }

  Future<void> _loadPrices() async {
    final repo = ref.read(priceRepositoryProvider);
    final prices = await repo.getPricesByDate(_selectedDate);
    
    setState(() {
      for (final price in prices) {
        if (_controllers.containsKey(price.productId)) {
          _controllers[price.productId]!.text = price.price.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسعيرة الأصناف اليومية'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: ref.watch(productsStreamProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('خطأ: $err')),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text('لا توجد أصناف مسجلة'));
                      }
                      
                      // Initialize controllers for new products
                      for (final p in products) {
                        _controllers.putIfAbsent(p.id!, TextEditingController.new);
                      }

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Card(
                            child: ListTile(
                              title: Text(product.name),
                              trailing: SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _controllers[product.id],
                                  decoration: const InputDecoration(
                                    suffixText: '₪',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePrices,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('حفظ الأسعار', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          await _loadPrices();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('التاريخ:', style: TextStyle(fontSize: 16)),
            Text(
              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrices() async {
    final List<ProductPrice> pricesToSave = [];
    _controllers.forEach((productId, controller) {
      final price = double.tryParse(controller.text) ?? 0.0;
      if (price > 0) {
        pricesToSave.add(ProductPrice(
          productId: productId,
          price: price,
          date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        ),);
      }
    });

    if (pricesToSave.isEmpty) {
      return;
    }

    try {
      await ref.read(priceRepositoryProvider).updateMultiplePrices(pricesToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار لليوم')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }
}
