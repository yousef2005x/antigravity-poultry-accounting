import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';
import 'package:poultry_accounting/backend/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/supplier.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key, this.invoice});
  final PurchaseInvoice? invoice;

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  final List<PurchaseInvoiceItem> _items = [];
  double _discount = 0;
  double _additionalCosts = 0;
  final _notesController = TextEditingController();
  late TextEditingController _discountController;
  late TextEditingController _additionalCostsController;
  String _invoiceNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _selectedSupplier = widget.invoice!.supplier;
      _items.addAll(widget.invoice!.items);
      _discount = widget.invoice!.discount;
      _additionalCosts = widget.invoice!.additionalCosts;
      _notesController.text = widget.invoice!.notes ?? '';
      _invoiceNumber = widget.invoice!.invoiceNumber;
    } else {
      _generateInvoiceNumber();
    }
    _discountController = TextEditingController(text: _discount.toString());
    _additionalCostsController = TextEditingController(text: _additionalCosts.toString());
  }

  Future<void> _generateInvoiceNumber() async {
    final repo = ref.read(purchaseRepositoryProvider);
    final num = await repo.generatePurchaseInvoiceNumber();
    setState(() => _invoiceNumber = num);
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.calculatedTotal);
  double get _total => _subtotal - _discount + _additionalCosts;

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _additionalCostsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'ظپط§طھظˆط±ط© ظ…ط´طھط±ظٹط§طھ ط¬ط¯ظٹط¯ط©' : 'طھط¹ط¯ظٹظ„ ظپط§طھظˆط±ط© ظ…ط´طھط±ظٹط§طھ'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Row(
              children: [
                // Items Side
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSupplierSelector(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ط§ظ„ط£طµظ†ط§ظپ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addLiveChickenItem,
                              icon: const Icon(Icons.airport_shuttle),
                              label: const Text('طھظˆط±ظٹط¯ ط¯ط¬ط§ط¬ ط±ظٹط´'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _buildItemsTable()),
                      ],
                    ),
                  ),
                ),
                // Totals Side
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(16),
                    child: _buildSummarySection(),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FutureBuilder<List<Supplier>>(
          future: ref.read(supplierRepositoryProvider).getAllSuppliers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            return DropdownButtonFormField<Supplier>(
              initialValue: _selectedSupplier,
              decoration: const InputDecoration(
                labelText: 'ط§ط®طھط± ط§ظ„ظ…ظˆط±ط¯',
                prefixIcon: Icon(Icons.local_shipping),
                border: InputBorder.none,
              ),
              items: snapshot.data!.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (val) => setState(() => _selectedSupplier = val),
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
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ط§ظ„طµظ†ظپ', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ظƒظ…ظٹط©', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط³ط¹ط± ط§ظ„طھظƒظ„ظپط©', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ط£طµظ†ط§ظپ ظ…ط¶ط§ظپط©'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(flex: 3, child: Text(item.productName)),
                            Expanded(child: Text('${item.quantity}')),
                            Expanded(child: Text('${item.unitCost} â‚ھ')),
                            Expanded(child: Text('${item.calculatedTotal} â‚ھ', style: const TextStyle(fontWeight: FontWeight.bold))),
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
        _summaryRow('ط§ظ„ظ…ط¬ظ…ظˆط¹:', '$_subtotal â‚ھ'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _discountController,
          decoration: const InputDecoration(labelText: 'ط®طµظ… (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() => _discount = double.tryParse(val) ?? 0.0);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _additionalCostsController,
          decoration: const InputDecoration(labelText: 'طھظƒط§ظ„ظٹظپ ط¥ط¶ط§ظپظٹط© (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() => _additionalCosts = double.tryParse(val) ?? 0.0);
          },
        ),
        const Spacer(),
        const Divider(thickness: 2),
        _summaryRow('ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ†ظ‡ط§ط¦ظٹ:', '$_total â‚ھ', isBold: true, fontSize: 24, color: Colors.blueGrey),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('طھط£ظƒظٹط¯ ظˆط­ظپط¸ ط§ظ„ط´ط±ط§ط،', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Future<void> _addLiveChickenItem() async {
    setState(() => _isLoading = true);
    try {
      final product = await ref.read(productRepositoryProvider).getProductById(AppConstants.liveChickenId);
      if (mounted) {
        _showAddItemDialog(isLive: true, preSelectedProduct: product);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _showAddItemDialog({bool isLive = false, Product? preSelectedProduct}) {
    Product? selectedProduct = preSelectedProduct;

    final qtyController = TextEditingController();
    final costController = TextEditingController();
    
    // Calculator Controllers
    final grossController = TextEditingController();
    final tareController = TextEditingController(text: '0.0');
    final countController = TextEditingController(text: '0');

    void calculateNet() {
      final gross = double.tryParse(grossController.text) ?? 0;
      final count = double.tryParse(countController.text) ?? 0;
      final tare = double.tryParse(tareController.text) ?? 0;
      final net = (gross - (count * tare)).clamp(0, double.infinity);
      if (net > 0) {
        qtyController.text = net.toStringAsFixed(2);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ ظ…ط´طھط±ظٹط§طھ'),
          content: SizedBox(
            width: 600, // Widen the dialog
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<Product>>(
                future: ref.read(productRepositoryProvider).getActiveProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }
                  final products = snapshot.data!;
                  
                  // Crucial: Ensure the selectedProduct is the exact instance from the list
                  // or at least matches by ID to avoid Dropdown assertion error
                  Product? matchingProduct;
                  if (selectedProduct != null) {
                    try {
                      matchingProduct = products.firstWhere((p) => p.id == selectedProduct?.id);
                    } catch (_) {
                      // If not found in active list, don't pre-select
                    }
                  }

                  return DropdownButtonFormField<Product>(
                    value: matchingProduct,
                    decoration: const InputDecoration(labelText: 'ط§ظ„طµظ†ظپ'),
                    items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: isLive ? null : (val) {
                      setDialogState(() {
                        selectedProduct = val;
                        if (val != null) {
                          costController.text = val.defaultPrice.toString();
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              // Weight Calculator Section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: Column(
                  children: [
                    const Text('ط­ط§ط³ط¨ط© ط§ظ„ظˆط²ظ† (ظ„ظ„ط¯ط¬ط§ط¬ ط§ظ„ط±ظٹط´)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: grossController,
                            decoration: const InputDecoration(labelText: 'ط§ظ„ظˆط²ظ† ط§ظ„ظ‚ط§ط¦ظ…', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculateNet(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: countController,
                            decoration: const InputDecoration(labelText: 'ط¹ط¯ط¯ ط§ظ„ط£ظ‚ظپط§طµ', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculateNet(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: tareController,
                            decoration: const InputDecoration(labelText: 'ظˆط²ظ† ط§ظ„ظ‚ظپطµ', isDense: true),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculateNet(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'ط§ظ„طµط§ظپظٹ (ط§ظ„ظƒظ…ظٹط©)', 
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'ط³ط¹ط± ط§ظ„طھظƒظ„ظپط© ظ„ظ„ظƒظٹظ„ظˆ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ط¥ظ„ط؛ط§ط،')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) {
                  return;
                }
                final qty = double.tryParse(qtyController.text) ?? 0.0;
                final cost = double.tryParse(costController.text) ?? 0.0;
                if (qty > 0) {
                  setState(() {
                    _items.add(PurchaseInvoiceItem(
                      productId: selectedProduct!.id!,
                      productName: selectedProduct!.name,
                      quantity: qty,
                      unitCost: cost,
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

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„ظ…ظˆط±ط¯')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظ„ط§ ظٹظ…ظƒظ† ط­ظپط¸ ظپط§طھظˆط±ط© ظپط§ط±ط؛ط©')));
      return;
    }

    final invoice = PurchaseInvoice(
      id: widget.invoice?.id,
      invoiceNumber: _invoiceNumber,
      supplierId: _selectedSupplier!.id!,
      invoiceDate: DateTime.now(),
      status: InvoiceStatus.confirmed, // Direct confirm for now
      items: _items,
      discount: _discount,
      additionalCosts: _additionalCosts,
      notes: _notesController.text,
    );

    try {
      final repo = ref.read(purchaseRepositoryProvider);
      if (widget.invoice == null) {
        final id = await repo.createPurchaseInvoice(invoice);
        await repo.confirmPurchaseInvoice(id, 1); // Mock user ID 1
      } else {
        await repo.updatePurchaseInvoice(invoice);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط­ظپط¸ ظˆطھط£ظƒظٹط¯ ظپط§طھظˆط±ط© ط§ظ„ظ…ط´طھط±ظٹط§طھ')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ظپط¸: $e')));
      }
    }
  }
}
