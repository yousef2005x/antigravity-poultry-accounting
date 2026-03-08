import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';

class SalesInvoiceFormScreen extends ConsumerStatefulWidget {
  const SalesInvoiceFormScreen({super.key, this.invoice});
  final Invoice? invoice;

  @override
  ConsumerState<SalesInvoiceFormScreen> createState() => _SalesInvoiceFormScreenState();
}

class _SalesInvoiceFormScreenState extends ConsumerState<SalesInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  final List<InvoiceItem> _items = [];
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _paidAmountController;
  final _notesController = TextEditingController();
  String _invoiceNumber = '';
  double _discount = 0;
  double _tax = 0;
  double _paidAmount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _selectedCustomer = widget.invoice!.customer;
      _items.addAll(widget.invoice!.items);
      _discount = widget.invoice!.discount;
      _tax = widget.invoice!.tax;
      _paidAmount = widget.invoice!.paidAmount;
      _notesController.text = widget.invoice!.notes ?? '';
      _invoiceNumber = widget.invoice!.invoiceNumber;
    } else {
      _generateInvoiceNumber();
    }
    _discountController = TextEditingController(text: _discount.toString());
    _taxController = TextEditingController(text: _tax.toString());
    _paidAmountController = TextEditingController(text: _paidAmount.toString());
  }

  Future<void> _generateInvoiceNumber() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final num = await repo.generateInvoiceNumber();
    setState(() => _invoiceNumber = num);
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total => _subtotal - _discount + _tax;

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ref.watch(customersStreamProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('ط®ط·ط£: $err'),
              data: (customers) {
                return DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'ط§ط®طھط± ط§ظ„ط¹ظ…ظٹظ„ *',
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => val == null ? 'ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„ط¹ظ…ظٹظ„' : null,
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
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ط§ظ„طµظ†ظپ', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط§ظ„ظƒظ…ظٹط©', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('ط³ط¹ط± ط§ظ„ظˆط­ط¯ط©', style: TextStyle(fontWeight: FontWeight.bold))),
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
        _summaryRow('ط§ظ„ظ…ط¬ظ…ظˆط¹:', '$_subtotal â‚ھ'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _discountController,
          decoration: const InputDecoration(labelText: 'ط®طµظ… (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _taxController,
          decoration: const InputDecoration(labelText: 'ط¶ط±ظٹط¨ط© (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _tax = double.tryParse(val) ?? 0.0),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _paidAmountController,
          decoration: const InputDecoration(labelText: 'ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ (â‚ھ)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _paidAmount = double.tryParse(val) ?? 0.0),
        ),
        const Spacer(),
        const Divider(thickness: 2),
        _summaryRow('ط§ظ„طµط§ظپظٹ:', '$_total â‚ھ', isBold: true, fontSize: 24, color: Colors.blueAccent),
        _summaryRow('ط§ظ„ظ…طھط¨ظ‚ظٹ (ط¯ظٹظ†):', '${_total - _paidAmount} â‚ھ', color: Colors.red),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('ط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط©', style: TextStyle(fontSize: 18, color: Colors.white)),
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
    final qtyController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ ظ„ظ„ظپط§طھظˆط±ط©'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ref.watch(productsStreamProvider).when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, stack) => Text('ط®ط·ط£: $err'),
                    data: (products) {
                      return DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(labelText: 'ط§ظ„طµظ†ظپ'),
                        items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                        onChanged: (val) async {
                          setDialogState(() => selectedProduct = val);
                          if (val != null) {
                            final priceRepo = ref.read(priceRepositoryProvider);
                            final latest = await priceRepo.getLatestPrice(val.id!);
                            
                            // NEW: Fetch current stock
                            final productRepo = ref.read(productRepositoryProvider);
                            final stock = await productRepo.getCurrentStock(val.id!);
                            
                            setDialogState(() {
                              priceController.text = (latest?.price ?? val.defaultPrice).toString();
                              qtyController.text = ''; // Reset qty on change
                            });
                            
                            // Show available stock info
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…طھظˆظپط±ط© ظ…ظ† ${val.name}: $stock ظƒط؛'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ظƒظ…ظٹط©', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'ط³ط¹ط± ط§ظ„ط¨ظٹط¹', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ط¥ظ„ط؛ط§ط،')),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct == null) {
                  return;
                }
                final qty = double.tryParse(qtyController.text) ?? 0.0;
                
                // NEW: Validate against stock
                final stock = await ref.read(productRepositoryProvider).getCurrentStock(selectedProduct!.id!);
                if (qty > stock) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ط®ط·ط£: ط§ظ„ظƒظ…ظٹط© ط§ظ„ظ…ط·ظ„ظˆط¨ط© ($qty) ط£ظƒط¨ط± ظ…ظ† ط§ظ„ظ…طھظˆظپط± ($stock)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final price = double.tryParse(priceController.text) ?? 0.0;
                if (qty > 0) {
                  setState(() {
                    _items.add(InvoiceItem(
                      productId: selectedProduct!.id!,
                      productName: selectedProduct!.name,
                      quantity: qty,
                      unitPrice: price,
                      costAtSale: 0,
                    ),);
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('ط¥ط¶ط§ظپط©'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save({InvoiceStatus? status}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ظ„ط§ ظٹظ…ظƒظ† ط­ظپط¸ ظپط§طھظˆط±ط© ظپط§ط±ط؛ط©')));
      return;
    }

    setState(() => _isSaving = true);

    final isFullyPaid = _paidAmount >= _total;
    final finalStatus = status ?? (isFullyPaid ? InvoiceStatus.confirmed : InvoiceStatus.draft);
    
    final invoice = Invoice(
      id: widget.invoice?.id,
      invoiceNumber: _invoiceNumber,
      customerId: _selectedCustomer!.id!,
      invoiceDate: DateTime.now(),
      status: finalStatus,
      items: _items,
      discount: _discount,
      tax: _tax,
      paidAmount: _paidAmount,
      notes: _notesController.text,
    );

    try {
      final repo = ref.read(invoiceRepositoryProvider);
      if (widget.invoice == null) {
        final invoiceId = await repo.createInvoice(invoice);
        
        if (finalStatus == InvoiceStatus.confirmed) {
          await repo.confirmInvoice(invoiceId, 1); // TODO: Use actual user ID
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط© (ظ…ط¤ظƒط¯ط© - طھظ… ط®طµظ… ط§ظ„ظ…ط®ط²ظˆظ†)')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ظپط§طھظˆط±ط© (ظ…ط³ظˆط¯ط©)')));
          }
        }
      } else {
        await repo.updateInvoice(invoice);
        // If it was draft and now we are confirming
        if (widget.invoice!.status == InvoiceStatus.draft && finalStatus == InvoiceStatus.confirmed) {
           await repo.confirmInvoice(widget.invoice!.id!, 1); // TODO: Use actual user ID
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… طھط­ط¯ظٹط« ظˆطھط£ظƒظٹط¯ ط§ظ„ظپط§طھظˆط±ط© ظˆط®طµظ… ط§ظ„ظ…ط®ط²ظˆظ†')));
           }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… طھط­ط¯ظٹط« ط§ظ„ظپط§طھظˆط±ط©')));
          }
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط®ط·ط£: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = widget.invoice?.status == InvoiceStatus.confirmed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'ظپط§طھظˆط±ط© ظ…ط¨ظٹط¹ط§طھ ط¬ط¯ظٹط¯ط©' : 'طھط¹ط¯ظٹظ„ ظپط§طھظˆط±ط© ظ…ط¨ظٹط¹ط§طھ'),
        actions: [
          if (!isConfirmed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'ط­ظپط¸ ظˆطھط£ظƒظٹط¯ (ط®طµظ… ظ…ط®ط²ظˆظ†)',
              onPressed: () => _save(status: InvoiceStatus.confirmed),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(),
          ),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isConfirmed)
                    const Card(
                      color: Colors.amber,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.lock),
                            SizedBox(width: 8),
                            Text('ظ‡ط°ظ‡ ط§ظ„ظپط§طھظˆط±ط© ظ…ط¤ظƒط¯ط© ظˆطھظ… ط®طµظ…ظ‡ط§ ظ…ظ† ط§ظ„ظ…ط®ط²ظˆظ†. ط§ظ„طھط¹ط¯ظٹظ„ ظ…ط­ط¯ظˆط¯.', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  _buildHeader(),
                  const Divider(height: 32),
                  _buildItemsList(),
                  const Divider(height: 32),
                  _buildTotalsSection(),
                  const SizedBox(height: 32),
                  if (!isConfirmed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('ط­ظپط¸ ظƒظ…ط³ظˆط¯ط© (ظ„ط§ ظٹط®طµظ… ظ…ط®ط²ظˆظ†)'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (!isConfirmed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _save(status: InvoiceStatus.confirmed),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('ط­ظپط¸ ظˆطھط£ظƒظٹط¯ (ظٹط®طµظ… ظ…ظ† ط§ظ„ظ…ط®ط²ظˆظ†)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ط±ظ‚ظ… ط§ظ„ظپط§طھظˆط±ط©: $_invoiceNumber',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'ط§ظ„طھط§ط±ظٹط®: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCustomerSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ط§ظ„ط£طµظ†ط§ظپ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('ط¥ط¶ط§ظپط© طµظ†ظپ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildItemsTable(),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('ط§ظ„ظ…ط¬ظ…ظˆط¹:', '$_subtotal â‚ھ'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(labelText: 'ط®طµظ… (â‚ھ)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxController,
              decoration: const InputDecoration(labelText: 'ط¶ط±ظٹط¨ط© (â‚ھ)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _tax = double.tryParse(val) ?? 0.0),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paidAmountController,
              decoration: const InputDecoration(labelText: 'ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ظ…ط¯ظپظˆط¹ (â‚ھ)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _paidAmount = double.tryParse(val) ?? 0.0),
            ),
            const Divider(thickness: 2),
            _summaryRow('ط§ظ„طµط§ظپظٹ:', '$_total â‚ھ', isBold: true, fontSize: 24, color: Colors.blueAccent),
            _summaryRow('ط§ظ„ظ…طھط¨ظ‚ظٹ (ط¯ظٹظ†):', '${_total - _paidAmount} â‚ھ', color: Colors.red),
          ],
        ),
      ),
    );
  }
}
