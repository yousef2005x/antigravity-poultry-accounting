import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/entities/expense.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';
import 'package:poultry_accounting/backend/domain/entities/stock_conversion.dart';

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
        title: const Text('طھط­ظˆظٹظ„ ط§ظ„ظ…ط®ط²ظˆظ† (ط§ظ„طھظ‚ط·ظٹط¹)'),
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
                      label: Text(_isTransferring ? 'ط­ظپط¸ ظˆطھط±ط­ظٹظ„ ظ„ظ„ط¹ظ…ظٹظ„' : 'ط­ظپط¸ ط§ظ„طھط­ظˆظٹظ„'),
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
            const Text('ط§ظ„ظ…طµط¯ط± (ط§ظ„ط®ط§ظ…)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ref.watch(productsStreamProvider).when(
              data: (products) {
                final listToShow = products.where((p) => p.productType == ProductType.intermediate).toList();

                return DropdownButtonFormField<Product>(
                  initialValue: _sourceProduct ?? (listToShow.isNotEmpty ? listToShow.first : null),
                  decoration: const InputDecoration(
                    labelText: 'ط§ظ„ظ…ظ†طھط¬ ط§ظ„ظ…طµط¯ط± (ط¯ط¬ط§ط¬ ظƒط§ظ…ظ„)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: listToShow.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => _sourceProduct = val),
                  validator: (val) => val == null ? 'ظ…ط·ظ„ظˆط¨' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceQuantityController,
              decoration: const InputDecoration(
                labelText: 'ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط³ط­ظˆط¨ط© (ظƒط؛)',
                border: OutlineInputBorder(),
                suffixText: 'ظƒط؛',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'ظ…ط·ظ„ظˆط¨';
                }
                final v = double.tryParse(val);
                if (v == null || v <= 0) {
                  return 'ظ‚ظٹظ…ط© ط؛ظٹط± طµط§ظ„ط­ط©';
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
            const Text('ط§ظ„ظ†ظˆط§طھط¬ (ط§ظ„ط£طµظ†ط§ظپ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: _showAddOutputDialog,
              icon: const Icon(Icons.add),
              label: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_outputs.isEmpty)
          const Center(child: Text('ظ„ظ… ظٹطھظ… ط¥ط¶ط§ظپط© ط£طµظ†ط§ظپ ط¨ط¹ط¯', style: TextStyle(color: Colors.grey)))
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
                  subtitle: Text('${item.quantity} ظƒط؛ (${item.yieldPercentage.toStringAsFixed(1)}%)'),
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
            _summaryRow('ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط³ط­ظˆط¨ط©:', '${_totalSourceQuantity.toStringAsFixed(2)} ظƒط؛'),
            const Divider(),
            _summaryRow('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ†ظˆط§طھط¬:', '${_totalOutputQuantity.toStringAsFixed(2)} ظƒط؛', isBold: true),
            _summaryRow('ط§ظ„ظپط§ظ‚ط¯ (ظ‡ط¯ط±/ط¹ط¸ظ…):', '${_processingLoss.toStringAsFixed(2)} ظƒط؛', 
              color: _processingLoss > (_totalSourceQuantity * 0.3) ? Colors.red : Colors.orange,
            ), // Warn if > 30% loss
            const Divider(),
            // Bug 4 Fix: Add to Inventory option
            CheckboxListTile(
              value: _addToInventory,
              onChanged: _isTransferring ? null : (val) => setState(() => _addToInventory = val ?? false),
              title: const Text('ط¥ط¶ط§ظپط© ط§ظ„ظ†ظˆط§طھط¬ ظ„ظ„ظ…ط®ط²ظˆظ†', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('ط³ظٹطھظ… ط¥ط¶ط§ظپط© ط§ظ„ط£طµظ†ط§ظپ ط§ظ„ظ…ظڈظ‚ط·ظ‘ط¹ط© ظ„ظ„ظ…ط®ط²ظˆظ† ظ„ظ„ط¨ظٹط¹ ظ„ط§ط­ظ‚ط§ظ‹'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط±ط¬ظ‰ طھط­ط¯ظٹط¯ ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط³ط­ظˆط¨ط© ط£ظˆظ„ط§ظ‹')));
      return;
    }

    Product? selectedProduct;
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ط¥ط¶ط§ظپط© ظ†ط§طھط¬'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ref.watch(productsStreamProvider).when(
              data: (products) => DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'ط§ظ„طµظ†ظپ ط§ظ„ظ†ط§طھط¬'),
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
              decoration: const InputDecoration(labelText: 'ط§ظ„ظƒظ…ظٹط© (ظƒط؛)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ط¥ظ„ط؛ط§ط،')),
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
            child: const Text('ط¥ط¶ط§ظپط©'),
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
              title: const Text('طھط±ط­ظٹظ„ ظ…ط¨ط§ط´ط± ظ„ط­ط³ط§ط¨ ط§ظ„ط¹ظ…ظٹظ„', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('ط³ظٹطھظ… ط¥ظ†ط´ط§ط، ظپط§طھظˆط±ط© ظ…ط¨ظٹط¹ط§طھ طھظ„ظ‚ط§ط¦ظٹط§ظ‹ ط¨ظ‡ط°ظ‡ ط§ظ„ط£طµظ†ط§ظپ'),
              secondary: const Icon(Icons.person_add),
            ),
            if (_isTransferring) ...[
              const Divider(),
              ref.watch(customersStreamProvider).when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'ط§ط®طھط± ط§ظ„ط¹ظ…ظٹظ„',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => _isTransferring && val == null ? 'ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„' : null,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط¬ط¨ ط¥ط¶ط§ظپط© طµظ†ظپ ظˆط§ط­ط¯ ط¹ظ„ظ‰ ط§ظ„ط£ظ‚ظ„')));
      return;
    }
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„ ط£ظˆظ„ط§ظ‹')));
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
              content: Text('ظ„ط§ ظٹظˆط¬ط¯ ظ…ط®ط²ظˆظ† ظƒط§ظپظٹ. ط§ظ„ظ…طھظˆظپط±: ${availableStock.toStringAsFixed(2)} ظƒط؛'),
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
        notes: 'طھظ… ط¥ظ†ط´ط§ط¤ظ‡ط§ طھظ„ظ‚ط§ط¦ظٹط§ظ‹ ظ…ظ† ط¹ظ…ظ„ظٹط© ط§ظ„طھط­ظˆظٹظ„',
      );

      await invoiceRepo.createInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('طھظ… ط§ظ„طھط­ظˆظٹظ„ ظˆطھط¨ظ„ط؛ ط§ظ„طھظƒظ„ظپط© ط¨ظ†ط¬ط§ط­ ظˆطھط±ط­ظٹظ„ظ‡ط§ ظ„ظ„ظپط§طھظˆط±ط©'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط¬ط¨ ط¥ط¶ط§ظپط© طµظ†ظپ ظˆط§ط­ط¯ ط¹ظ„ظ‰ ط§ظ„ط£ظ‚ظ„')));
      return;
    }
    if (_processingLoss < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ط§ظ„ظ†ظˆط§طھط¬ ط£ظƒط¨ط± ظ…ظ† ط§ظ„ظ…طµط¯ط±!')));
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
              content: Text('ظ„ط§ ظٹظˆط¬ط¯ ظ…ط®ط²ظˆظ† ظƒط§ظپظٹ. ط§ظ„ظ…طھظˆظپط±: ${availableStock.toStringAsFixed(2)} ظƒط؛'),
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
          content: Text('طھظ… ط­ظپط¸ ط¹ظ…ظ„ظٹط© ط§ظ„طھط­ظˆظٹظ„ ط¨ظ†ط¬ط§ط­ (ط§ظ„ط£طµظ†ط§ظپ ط§ظ„ظ†ظ‡ط§ط¦ظٹط© ظ„ظ… طھط¶ظپ ظ„ظ„ظ…ط®ط²ظˆظ† ط­ط³ط¨ ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ)'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
