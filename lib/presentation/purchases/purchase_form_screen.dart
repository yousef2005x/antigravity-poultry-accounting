import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';

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
        title: Text(widget.invoice == null ? 'فاتورة مشتريات جديدة' : 'تعديل فاتورة مشتريات'),
        backgroundColor: Colors.blueGrey,
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
                    _buildSupplierSelector(),
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
        backgroundColor: Colors.blueGrey,
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
                labelText: 'اختر المورد',
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
                Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('سعر التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
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
                            Expanded(child: Text('${item.unitCost} ₪')),
                            Expanded(child: Text('${item.calculatedTotal} ₪', style: const TextStyle(fontWeight: FontWeight.bold))),
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
          onChanged: (val) {
            setState(() => _discount = double.tryParse(val) ?? 0.0);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _additionalCostsController,
          decoration: const InputDecoration(labelText: 'تكاليف إضافية (₪)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() => _additionalCosts = double.tryParse(val) ?? 0.0);
          },
        ),
        const Spacer(),
        const Divider(thickness: 2),
        _summaryRow('الإجمالي النهائي:', '$_total ₪', isBold: true, fontSize: 24, color: Colors.blueGrey),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('تأكيد وحفظ الشراء', style: TextStyle(fontSize: 18, color: Colors.white)),
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
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة صنف مشتريات'),
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
                    decoration: const InputDecoration(labelText: 'الصنف'),
                    items: snapshot.data!.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedProduct = val;
                        costController.text = val?.defaultPrice.toString() ?? '0.0';
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'الكمية / الوزن', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'سعر التكلفة للوحدة', border: OutlineInputBorder()),
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
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار المورد')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حفظ فاتورة فارغة')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ وتأكيد فاتورة المشتريات')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }
}
