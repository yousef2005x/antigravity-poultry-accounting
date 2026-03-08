import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';

class SalesInvoiceScreen extends ConsumerStatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  ConsumerState<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends ConsumerState<SalesInvoiceScreen> {

  
  Customer? _selectedCustomer;
  final List<InvoiceItem> _items = [];
  double _discount = 0;
  final _notesController = TextEditingController();
  String _invoiceNumber = '';

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }

  Future<void> _generateInvoiceNumber() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final num = await repo.generateInvoiceNumber();
    setState(() => _invoiceNumber = num);
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal - _discount;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ظپط§طھظˆط±ط© ظ…ط¨ظٹط¹ط§طھ ط¬ط¯ظٹط¯ط© ($_invoiceNumber)'),
        backgroundColor: Colors.green,
      ),
      body: Row(
        children: [
          // Main Form Side
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   _buildCustomerSelector(),
                   const SizedBox(height: 16),
                   Expanded(child: _buildItemsTable()),
                ],
              ),
            ),
          ),
          // Total & Summary Side
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: _buildSummarySection(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        label: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder<List<Customer>>(
          future: ref.read(customerRepositoryProvider).getActiveCustomers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final customers = snapshot.data!;
            return DropdownButtonFormField<Customer>(
              initialValue: _selectedCustomer,
              decoration: const InputDecoration(
                labelText: 'ط§ط®طھط± ط§ظ„ط¹ظ…ظٹظ„',
                prefixIcon: Icon(Icons.person),
                border: InputBorder.none,
              ),
              items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Card(
      child: Column(
        children: [
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ط§ظ„طµظ†ظپ', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ظˆط²ظ†/ط§ظ„ظƒظ…ظٹط©', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ط³ط¹ط± ط§ظ„ط¥ظپط±ط§ط¯ظٹ', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty 
              ? const Center(child: Text('ظ„ط§ ظٹظˆط¬ط¯ ط£طµظ†ط§ظپ ظپظٹ ط§ظ„ظپط§طھظˆط±ط© ط¨ط¹ط¯'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item.productName)),
                          Expanded(child: Text('${item.quantity}')),
                          Expanded(child: Text('${item.unitPrice} â‚ھ')),
                          Expanded(child: Text('${item.total} â‚ھ', style: const TextStyle(fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ظ…ظ„ط®طµ ط§ظ„ظپط§طھظˆط±ط©', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        _summaryRow('ط§ظ„ظ…ط¬ظ…ظˆط¹ ط§ظ„ظپط±ط¹ظٹ:', '$_subtotal â‚ھ'),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(labelText: 'ط®طµظ… ط¥ط¬ظ…ط§ظ„ظٹ (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
        ),
        const Spacer(),
        const Divider(thickness: 2),
        _summaryRow('ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ†ظ‡ط§ط¦ظٹ:', '$_total â‚ھ', isBold: true, fontSize: 24, color: Colors.green),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _saveInvoice,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('طھط£ظƒظٹط¯ ظˆط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط©', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 16, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showAddItemDialog() {
    Product? selectedProduct;
    final weightController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ ظ„ظ„ظپط§طھظˆط±ط©'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<Product>>(
                future: ref.read(productRepositoryProvider).getActiveProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }
                  return DropdownButtonFormField<Product>(
                    initialValue: selectedProduct,
                    decoration: const InputDecoration(labelText: 'ط§ط®طھط± ط§ظ„طµظ†ظپ'),
                    items: snapshot.data!.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) async {
                      setDialogState(() => selectedProduct = val);
                      // Fetch daily price for this product
                      if (val != null) {
                        final priceRepo = ref.read(priceRepositoryProvider);
                        final latest = await priceRepo.getLatestPrice(val.id!);
                        setDialogState(() => priceController.text = (latest?.price ?? val.defaultPrice).toString());
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ظˆط²ظ† / ط§ظ„ظƒظ…ظٹط©', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ط³ط¹ط± ط§ظ„ط¥ظپط±ط§ط¯ظٹ (â‚ھ)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ط¥ظ„ط؛ط§ط،')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) {
                  return;
                }
                final weight = double.tryParse(weightController.text) ?? 0.0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                
                if (weight > 0 && price >= 0) {
                  setState(() {
                    _items.add(InvoiceItem(
                      productId: selectedProduct!.id!,
                      productName: selectedProduct!.name,
                      quantity: weight,
                      unitPrice: price,
                      costAtSale: 0, // Should be fetched from inventory
                    ),);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ط¥ط¶ط§ظپط©'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظ„ط§ ظٹظ…ظƒظ† ط­ظپط¸ ظپط§طھظˆط±ط© ظپط§ط±ط؛ط©')));
      return;
    }

    final repo = ref.read(invoiceRepositoryProvider);
    final invoice = Invoice(
      invoiceNumber: _invoiceNumber,
      customerId: _selectedCustomer!.id!,
      invoiceDate: DateTime.now(),
      status: InvoiceStatus.confirmed,
      items: _items,
      discount: _discount,
    );

    try {
      await repo.createInvoice(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط© ط¨ظ†ط¬ط§ط­')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ظپط¸: $e')));
      }
    }
  }
}
