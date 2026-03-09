import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/product_price.dart';

class LiveChickenPricingScreen extends ConsumerStatefulWidget {
  const LiveChickenPricingScreen({super.key});

  @override
  ConsumerState<LiveChickenPricingScreen> createState() => _LiveChickenPricingScreenState();
}

class _LiveChickenPricingScreenState extends ConsumerState<LiveChickenPricingScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _priceController = TextEditingController();
  int? _chickenProductId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final products = await ref.read(productRepositoryProvider).getAllProducts();
      // Try to find a product that represents Live Chicken
      final chicken = products.firstWhere(
        (p) => p.name.contains('ريش') || p.name.contains('دجاج') || p.name.contains('جاج'),
        orElse: () => products.first, // Fallback to first product if none found
      );
      
      setState(() {
        _chickenProductId = chicken.id;
      });
      unawaited(_loadPrice());
    });
  }

  Future<void> _loadPrice() async {
    if (_chickenProductId == null) {
      return;
    }
    
    final repo = ref.read(priceRepositoryProvider);
    final prices = await repo.getPricesByDate(_selectedDate);
    
    final chickenPrice = prices.where((p) => p.productId == _chickenProductId).firstOrNull;
    
    setState(() {
      if (chickenPrice != null) {
        _priceController.text = chickenPrice.price.toString();
      } else {
        _priceController.clear();
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسعيرة الجاج الريش'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   const Icon(Icons.shopping_basket, size: 60, color: Colors.green),
                   const SizedBox(height: 16),
                   const Text(
                    'سعر كيلو الجاج الريش',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _priceController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      suffixText: '₪',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _savePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  'حفظ التسعيرة',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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
          await _loadPrice();
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
            const Text('تاريخ التسعيرة:', style: TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrice() async {
    if (_chickenProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: لم يتم العثور على صنف الجاج')));
      return;
    }

    final priceValue = double.tryParse(_priceController.text) ?? 10.0;
    
    final priceToSave = ProductPrice(
      productId: _chickenProductId!,
      price: priceValue,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
    );

    try {
      await ref.read(priceRepositoryProvider).updateMultiplePrices([priceToSave]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ تسعيرة الجاج الريش بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }
}
