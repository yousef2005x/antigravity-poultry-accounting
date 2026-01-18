import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/entities/product.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'فاتورة مبيعات جديدة' : 'تعديل فاتورة مبيعات'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Form(
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
                    _buildCustomerSelector(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        label: const Text('إضافة صنف'),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ref.watch(customersStreamProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('خطأ: $err'),
              data: (customers) {
                return DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'اختر العميل *',
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCustomer = val),
                  validator: (val) => val == null ? 'يرجى اختيار العميل' : null,
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
                Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('سعر الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('لا توجد أصناف مضافة'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(flex: 3, child: Text(item.productName)),
                            Expanded(child: Text('${item.quantity}')),
                            Expanded(child: Text('${item.unitPrice} ₪')),
                            Expanded(child: Text('${item.total} ₪', style: const TextStyle(fontWeight: FontWeight.bold))),
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
        const Text('ملخص الفاتورة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        _summaryRow('المجموع:', '$_subtotal ₪'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _discountController,
          decoration: const InputDecoration(labelText: 'خصم (₪)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _taxController,
          decoration: const InputDecoration(labelText: 'ضريبة (₪)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _tax = double.tryParse(val) ?? 0.0),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _paidAmountController,
          decoration: const InputDecoration(labelText: 'المبلغ المدفوع (₪)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _paidAmount = double.tryParse(val) ?? 0.0),
        ),
        const Spacer(),
        const Divider(thickness: 2),
        _summaryRow('الصافي:', '$_total ₪', isBold: true, fontSize: 24, color: Colors.blueAccent),
        _summaryRow('المتبقي (دين):', '${_total - _paidAmount} ₪', color: Colors.red),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 18, color: Colors.white)),
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
          title: const Text('إضافة صنف للفاتورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ref.watch(productsStreamProvider).when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, stack) => Text('خطأ: $err'),
                    data: (products) {
                      return DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(labelText: 'الصنف'),
                        items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
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
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'سعر البيع', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) {
                  return;
                }
                final qty = double.tryParse(qtyController.text) ?? 0.0;
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (qty > 0) {
                  setState(() {
                    _items.add(InvoiceItem(
                      productId: selectedProduct!.id!,
                      productName: selectedProduct!.name,
                      quantity: qty,
                      unitPrice: price,
                      costAtSale: 0, // Should be fetched from inventory manager
                    ),);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حفظ فاتورة فارغة')));
      return;
    }

    final invoice = Invoice(
      id: widget.invoice?.id,
      invoiceNumber: _invoiceNumber,
      customerId: _selectedCustomer!.id!,
      invoiceDate: DateTime.now(),
      status: InvoiceStatus.draft, // Default to draft, can be confirmed late
      items: _items,
      discount: _discount,
      tax: _tax,
      paidAmount: _paidAmount,
      notes: _notesController.text,
    );

    try {
      final repo = ref.read(invoiceRepositoryProvider);
      if (widget.invoice == null) {
        await repo.createInvoice(invoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة (مسودة)')));
        }
      } else {
        await repo.updateInvoice(invoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الفاتورة')));
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}
