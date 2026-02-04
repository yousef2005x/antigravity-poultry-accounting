import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/expense.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/entities/stock_conversion.dart';

class StockConversionScreen extends ConsumerStatefulWidget {
  const StockConversionScreen({super.key});

  @override
  ConsumerState<StockConversionScreen> createState() => _StockConversionScreenState();
}

class _StockConversionScreenState extends ConsumerState<StockConversionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Source Selection
  Product? _sourceProduct;
  final _sourceQuantityController = TextEditingController();
  
  // Output Selection
  final List<StockConversionItem> _outputs = [];
  
  final _notesController = TextEditingController();
  
  // Customer Transfer
  Customer? _selectedCustomer;
  bool _isTransferring = false;
  
  // Add to Inventory Option (Bug 4 Fix)
  bool _addToInventory = false;

  @override
  void dispose() {
    _sourceQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalSourceQuantity => double.tryParse(_sourceQuantityController.text) ?? 0;
  
  double get _totalOutputQuantity => _outputs.fold(0.0, (sum, item) => sum + item.quantity);
  
  double get _processingLoss => (_totalSourceQuantity - _totalOutputQuantity).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل المخزون (التقطيع)'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSourceSection(),
                  const Divider(height: 32),
                  _buildOutputsSection(),
                  const SizedBox(height: 24),
                  _buildSummarySection(),
                  const SizedBox(height: 24),
                  _buildCustomerSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTransferring ? _saveAndTransfer : _saveConversion,
                      icon: Icon(_isTransferring ? Icons.send : Icons.save),
                      label: Text(_isTransferring ? 'حفظ وترحيل للعميل' : 'حفظ التحويل'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isTransferring ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSourceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المصدر (الخام)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ref.watch(productsStreamProvider).when(
              data: (products) {
                final listToShow = products.where((p) => p.productType == ProductType.intermediate).toList();

                return DropdownButtonFormField<Product>(
                  initialValue: _sourceProduct ?? (listToShow.isNotEmpty ? listToShow.first : null),
                  decoration: const InputDecoration(
                    labelText: 'المنتج المصدر (دجاج كامل)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: listToShow.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => _sourceProduct = val),
                  validator: (val) => val == null ? 'مطلوب' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceQuantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية المسحوبة (كغ)',
                border: OutlineInputBorder(),
                suffixText: 'كغ',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'مطلوب';
                }
                final v = double.tryParse(val);
                if (v == null || v <= 0) {
                  return 'قيمة غير صالحة';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('النواتج (الأصناف)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: _showAddOutputDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_outputs.isEmpty)
          const Center(child: Text('لم يتم إضافة أصناف بعد', style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _outputs.length,
            itemBuilder: (context, index) {
              final item = _outputs[index];
              final productId = item.productId;
              
              // Resolve product name
              final productAsync = ref.watch(productsStreamProvider);
              String productName = 'Product #$productId';
              productAsync.whenData((products) {
                try {
                  productName = products.firstWhere((p) => p.id == productId).name;
                } catch (_) {}
              });

              return Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.quantity} كغ (${item.yieldPercentage.toStringAsFixed(1)}%)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _outputs.removeAt(index)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('الكمية المسحوبة:', '${_totalSourceQuantity.toStringAsFixed(2)} كغ'),
            const Divider(),
            _summaryRow('إجمالي النواتج:', '${_totalOutputQuantity.toStringAsFixed(2)} كغ', isBold: true),
            _summaryRow('الفاقد (هدر/عظم):', '${_processingLoss.toStringAsFixed(2)} كغ', 
              color: _processingLoss > (_totalSourceQuantity * 0.3) ? Colors.red : Colors.orange,
            ), // Warn if > 30% loss
            const Divider(),
            // Bug 4 Fix: Add to Inventory option
            CheckboxListTile(
              value: _addToInventory,
              onChanged: _isTransferring ? null : (val) => setState(() => _addToInventory = val ?? false),
              title: const Text('إضافة النواتج للمخزون', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('سيتم إضافة الأصناف المُقطّعة للمخزون للبيع لاحقاً'),
              secondary: const Icon(Icons.inventory_2),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
            fontSize: isBold ? 16 : 14,
          ),),
        ],
      ),
    );
  }

  void _showAddOutputDialog() {
    if (_totalSourceQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد الكمية المسحوبة أولاً')));
      return;
    }

    Product? selectedProduct;
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ناتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ref.watch(productsStreamProvider).when(
              data: (products) => DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'الصنف الناتج'),
                items: products
                  .where((p) => p.productType == ProductType.finalProduct)
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
                onChanged: (val) => selectedProduct = val,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'الكمية (كغ)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text);
              if (selectedProduct != null && qty != null && qty > 0) {
                // Calculate Yield
                final yieldPct = (qty / _totalSourceQuantity) * 100;
                
                setState(() {
                  _outputs.add(StockConversionItem(
                    conversionId: 0, 
                    productId: selectedProduct!.id!, 
                    quantity: qty, 
                    yieldPercentage: yieldPct, 
                    unitCost: 0,
                  ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CheckboxListTile(
              value: _isTransferring,
              onChanged: (val) => setState(() => _isTransferring = val ?? false),
              title: const Text('ترحيل مباشر لحساب العميل', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('سيتم إنشاء فاتورة مبيعات تلقائياً بهذه الأصناف'),
              secondary: const Icon(Icons.person_add),
            ),
            if (_isTransferring) ...[
              const Divider(),
              ref.watch(customersStreamProvider).when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'اختر العميل',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => _isTransferring && val == null ? 'يرجى اختيار العميل' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndTransfer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')));
      return;
    }
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار العميل أولاً')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Bug 7.1 Fix: Check stock availability before conversion
      final availableStock = await ref.read(productRepositoryProvider).getCurrentStock(_sourceProduct!.id!);
      if (availableStock < _totalSourceQuantity) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يوجد مخزون كافي. المتوفر: ${availableStock.toStringAsFixed(2)} كغ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 1. Perform Conversion
      final conversion = StockConversion(
        conversionDate: DateTime.now(),
        sourceProductId: _sourceProduct!.id!,
        sourceQuantity: _totalSourceQuantity,
        notes: _notesController.text,
        createdBy: 1, // TODO Bug 8: Replace with actual user ID from AuthProvider
      );

      // forceInventory: false ensures ONLY intermediate (Whole Chicken) goes to stock
      // if it's a transfer, we probably don't even want the Whole Chicken record in stock batches?
      // Actually, convertStock REDUCES the source batch. The output is what we guard.
      final processedItems = await ref.read(stockConversionRepositoryProvider).convertStock(
        conversion: conversion,
        items: _outputs,
        forceInventory: false,
      );

      // 2. Create Sales Invoice
      final products = await ref.read(productsStreamProvider.future);
      final priceRepo = ref.read(priceRepositoryProvider);
      
      final enrichedItems = <InvoiceItem>[];
      for (final processed in processedItems) {
        final product = products.firstWhere((p) => p.id == processed.productId);
        final priceObj = await priceRepo.getLatestPrice(product.id!);
        
        enrichedItems.add(InvoiceItem(
           productId: product.id!,
           productName: product.name,
           quantity: processed.quantity,
           unitPrice: priceObj?.price ?? product.defaultPrice,
           costAtSale: processed.unitCost, // Using the calculated cost from conversion!
        ),
        );
      }

      final invoiceRepo = ref.read(invoiceRepositoryProvider);
      final invNum = await invoiceRepo.generateInvoiceNumber();
      
      final invoice = Invoice(
        invoiceNumber: invNum,
        customerId: _selectedCustomer!.id!,
        invoiceDate: DateTime.now(),
        status: InvoiceStatus.confirmed,
        items: enrichedItems,
        notes: 'تم إنشاؤها تلقائياً من عملية التحويل',
      );

      await invoiceRepo.createInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم التحويل وتبلغ التكلفة بنجاح وترحيلها للفاتورة'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveConversion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إضافة صنف واحد على الأقل')));
      return;
    }
    if (_processingLoss < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('النواتج أكبر من المصدر!')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      // Bug 7.1 Fix: Check stock availability before conversion
      final availableStock = await ref.read(productRepositoryProvider).getCurrentStock(_sourceProduct!.id!);
      if (availableStock < _totalSourceQuantity) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يوجد مخزون كافي. المتوفر: ${availableStock.toStringAsFixed(2)} كغ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final conversion = StockConversion(
        conversionDate: DateTime.now(),
        sourceProductId: _sourceProduct!.id!,
        sourceQuantity: _totalSourceQuantity,
        notes: _notesController.text,
        createdBy: 1, // TODO Bug 8: Replace with actual user ID from AuthProvider
      );

      // Bug 4 Fix: Use _addToInventory to allow user control over stock entry
      await ref.read(stockConversionRepositoryProvider).convertStock(
        conversion: conversion,
        items: _outputs,
        forceInventory: _addToInventory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ عملية التحويل بنجاح (الأصناف النهائية لم تضف للمخزون حسب الإعدادات)'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
