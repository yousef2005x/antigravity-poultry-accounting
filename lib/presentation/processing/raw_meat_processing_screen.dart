import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';

class RawMeatProcessingScreen extends ConsumerStatefulWidget {
  const RawMeatProcessingScreen({super.key});

  @override
  ConsumerState<RawMeatProcessingScreen> createState() => _RawMeatProcessingScreenState();
}

class _RawMeatProcessingScreenState extends ConsumerState<RawMeatProcessingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _grossWeightController = TextEditingController();
  final _basketWeightController = TextEditingController(text: '0.5'); // Default basket weight
  final _basketCountController = TextEditingController(text: '0');
  final _pricePerKgController = TextEditingController();
  final _notesController = TextEditingController();
  
  double _netWeight = 0;
  double _totalCost = 0;
  final List<ProcessingOutput> _outputs = [];
  
  @override
  void initState() {
    super.initState();
    _grossWeightController.addListener(_calculateValues);
    _basketWeightController.addListener(_calculateValues);
    _basketCountController.addListener(_calculateValues);
    _pricePerKgController.addListener(_calculateValues);
  }

  void _calculateValues() {
    final gross = double.tryParse(_grossWeightController.text) ?? 0.0;
    final basketWeight = double.tryParse(_basketWeightController.text) ?? 0.0;
    final basketCount = int.tryParse(_basketCountController.text) ?? 0;
    final pricePerKg = double.tryParse(_pricePerKgController.text) ?? 0.0;
    
    setState(() {
      _netWeight = gross - (basketWeight * basketCount);
      if (_netWeight < 0) {
        _netWeight = 0;
      }
      _totalCost = _netWeight * pricePerKg;
    });
  }

  @override
  void dispose() {
    _grossWeightController.dispose();
    _basketWeightController.dispose();
    _basketCountController.dispose();
    _pricePerKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال توريد خام وتجهيز'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRawInputSection(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildOutputsSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProcessing,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('حفظ العملية', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRawInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات المادة الخام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _grossWeightController,
                    decoration: const InputDecoration(labelText: 'الوزن القائم (كغ)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _basketCountController,
                    decoration: const InputDecoration(labelText: 'عدد السلال', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _basketWeightController,
                    decoration: const InputDecoration(labelText: 'وزن السلة الواحدة', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('الوزن الصافي', style: TextStyle(color: Colors.green)),
                        Text(
                          '${_netWeight.toStringAsFixed(2)} كغ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pricePerKgController,
                    decoration: const InputDecoration(labelText: 'سعر الكيلو (شيكل)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                         Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('التكلفة الإجمالية', style: TextStyle(color: Colors.blue)),
                        Text(
                          '${_totalCost.toStringAsFixed(2)} ₪',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
            const Text('الأصناف المستخرجة (الإنتاج)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showAddOutputDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ref.watch(productsStreamProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('خطأ: $err'),
              data: (products) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _outputs.length,
                  itemBuilder: (context, index) {
                    final output = _outputs[index];
                    final product = products.firstWhere((p) => p.id == output.productId, orElse: () => products.first);
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('الكمية: ${output.quantity} كغ'),
                        trailing: Text(
                          'النسبة: ${output.yieldPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _outputs.removeAt(index)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        if (_outputs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTotalYieldSummary(),
        ],
      ],
    );
  }

  Widget _buildTotalYieldSummary() {
    final totalQty = _outputs.fold<double>(0, (sum, item) => sum + item.quantity);
    final totalYield = _netWeight > 0 ? (totalQty / _netWeight) * 100 : 0.0;
    final waste = _netWeight - totalQty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _summaryRow('إجمالي وزن المخرجات:', '${totalQty.toStringAsFixed(2)} كغ'),
          _summaryRow('إجمالي نسبة التصافي:', '${totalYield.toStringAsFixed(1)}%'),
          _summaryRow('الفاقد / الهالك:', '${waste.toStringAsFixed(2)} كغ', isRed: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  void _showAddOutputDialog() {
    Product? selectedProduct;
    final qtyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة صنف منتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ref.watch(productsStreamProvider).when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('خطأ: $err'),
                  data: (products) {
                    return DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(labelText: 'اختر الصنف'),
                      items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (val) => selectedProduct = val,
                    );
                  },
                ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'الوزن (كغ)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (selectedProduct != null && qty > 0 && _netWeight > 0) {
                setState(() {
                  _outputs.add(ProcessingOutput(
                    processingId: 0, 
                    productId: selectedProduct!.id!,
                    quantity: qty,
                    yieldPercentage: (qty / _netWeight) * 100,
                  ),);
                });
                Navigator.pop(context);
              } else if (qty <= 0) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كمية صحيحة')));
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة صنف واحد على الأقل')));
      return;
    }

    final repo = ref.read(processingRepositoryProvider);
    final processing = RawMeatProcessing(
      batchNumber: 'BATCH-${DateTime.now().millisecondsSinceEpoch}',
      grossWeight: double.parse(_grossWeightController.text),
      basketWeight: double.parse(_basketWeightController.text),
      basketCount: int.parse(_basketCountController.text),
      netWeight: _netWeight,
      totalCost: _totalCost,
      processingDate: DateTime.now(),
      createdBy: 1, // Default admin
    );

    try {
      await repo.createProcessing(processing, _outputs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ العملية بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }
}
