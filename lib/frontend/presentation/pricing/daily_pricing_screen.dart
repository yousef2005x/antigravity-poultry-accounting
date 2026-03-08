import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/product_price.dart';

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
        title: const Text('ط§ظ„طھط³ط¹ظٹط±ط© ط§ظ„ظٹظˆظ…ظٹط© ظ„ظ„ط£طµظ†ط§ظپ'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: ref.watch(productsStreamProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ط£طµظ†ط§ظپ ظ…ط³ط¬ظ„ط©'));
                      }
                      
                      // Initialize controllers for new products
                      for (final p in products) {
                        _controllers.putIfAbsent(p.id!, TextEditingController.new);
                      }

                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                child: Icon(Icons.inventory, color: Colors.green.shade700, size: 20),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(product.unitDisplayName),
                              trailing: SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _controllers[product.id],
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    suffixText: 'â‚ھ',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.green, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _savePrices,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('ط­ظپط¸ ط¬ظ…ظٹط¹ ط§ظ„ط£ط³ط¹ط§ط±', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Colors.green.shade700),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          await _loadPrices();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            const Text('ط§ظ„طھط§ط±ظٹط®:', style: TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.green),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ط£ط³ط¹ط§ط± ظ„ظ„ظٹظˆظ…')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ظپط¸: $e')));
      }
    }
  }
}
