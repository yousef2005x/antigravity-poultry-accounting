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
  int _currentStep = 0;
  bool _isLoading = false;

  // Stage 1: Live
  final _liveGrossController = TextEditingController(text: '0');
  final _liveCrateWeightController = TextEditingController(text: '2.0'); // Default crate weight
  final _liveCrateCountController = TextEditingController(text: '0');
  final _pricePerKgController = TextEditingController(text: '0');
  
  // Stage 2: Slaughtered
  final _slaughterGrossController = TextEditingController(text: '0');
  final _slaughterBasketWeightController = TextEditingController(text: '0.6');
  final _slaughterBasketCountController = TextEditingController(text: '0');

  // Stage 3: Sorted Outputs
  final List<ProcessingOutput> _outputs = [];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _liveGrossController.dispose();
    _liveCrateWeightController.dispose();
    _liveCrateCountController.dispose();
    _pricePerKgController.dispose();
    _slaughterGrossController.dispose();
    _slaughterBasketWeightController.dispose();
    _slaughterBasketCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _liveNetWeight {
    final gross = double.tryParse(_liveGrossController.text) ?? 0;
    final tare = double.tryParse(_liveCrateWeightController.text) ?? 0;
    final count = int.tryParse(_liveCrateCountController.text) ?? 0;
    return (gross - (tare * count)).clamp(0, double.infinity);
  }

  double get _slaughterNetWeight {
    final gross = double.tryParse(_slaughterGrossController.text) ?? 0;
    final tare = double.tryParse(_slaughterBasketWeightController.text) ?? 0;
    final count = int.tryParse(_slaughterBasketCountController.text) ?? 0;
    return (gross - (tare * count)).clamp(0, double.infinity);
  }

  double get _shrinkageWeight => (_liveNetWeight - _slaughterNetWeight).clamp(0, double.infinity);
  double get _totalCost => _liveNetWeight * (double.tryParse(_pricePerKgController.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دورة التجهيز اليومية'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _saveProcessing();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentStep == 2 ? Colors.green : Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentStep == 2 ? 'حفظ وإكمال العملية' : 'التالي',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep == 0 ? 'إلغاء' : 'السابق'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('دجاج ريش'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.editing,
                content: _buildLiveIntakeSection(),
              ),
              Step(
                title: const Text('بعد الذبح'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.editing,
                content: _buildSlaughterSection(),
              ),
              Step(
                title: const Text('فرز الأصناف'),
                isActive: _currentStep >= 2,
                state: _currentStep == 2 ? StepState.editing : StepState.indexed,
                content: _buildSortingSection(),
              ),
            ],
          ),
    );
  }

  Widget _buildLiveIntakeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('توزين الدجاج الحي (في الصناديق)'),
        const SizedBox(height: 16),
        _buildWeightInputRow(
          grossController: _liveGrossController,
          countController: _liveCrateCountController,
          tareController: _liveCrateWeightController,
          grossLabel: 'الوزن القائم (ريش + صناديق)',
          countLabel: 'عدد الصناديق',
          tareLabel: 'وزن الصندوق الفارغ',
        ),
        const SizedBox(height: 16),
        _buildPriceAndCostSection(),
        const SizedBox(height: 16),
        _buildSummaryBox('الوزن الحي الصافي', _liveNetWeight, 'كغ', Colors.indigo),
      ],
    );
  }

  Widget _buildSlaughterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('توزين الدجاج بعد الذبح والتنظيف (في السلال)'),
        const SizedBox(height: 16),
        _buildWeightInputRow(
          grossController: _slaughterGrossController,
          countController: _slaughterBasketCountController,
          tareController: _slaughterBasketWeightController,
          grossLabel: 'الوزن القائم (مذبوح + سلال)',
          countLabel: 'عدد السلال',
          tareLabel: 'وزن السلة الفارغة',
        ),
        const SizedBox(height: 16),
        _buildSummaryBox('الوزن المذبوح الصافي', _slaughterNetWeight, 'كغ', Colors.green),
        const SizedBox(height: 8),
        _buildSummaryBox('إجمالي النقص (الهالك)', _shrinkageWeight, 'كغ', Colors.orange),
      ],
    );
  }

  Widget _buildSortingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('توزيع الأصناف (فرز)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showAddOutputDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOutputsList(),
        const SizedBox(height: 16),
        _buildSortingSummary(),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'ملاحظات إضافية', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildWeightInputRow({
    required TextEditingController grossController,
    required TextEditingController countController,
    required TextEditingController tareController,
    required String grossLabel,
    required String countLabel,
    required String tareLabel,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: grossController,
          decoration: InputDecoration(labelText: grossLabel, border: const OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: countController,
                decoration: InputDecoration(labelText: countLabel, border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: tareController,
                decoration: InputDecoration(labelText: tareLabel, border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndCostSection() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _pricePerKgController,
            decoration: const InputDecoration(labelText: 'سعر شراء الحي للكيلو', border: OutlineInputBorder(), suffixText: '₪'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryBox('إجمالي تكلفة الشراء', _totalCost, '₪', Colors.blue),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSummaryBox(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('${value.toStringAsFixed(2)} $unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildOutputsList() {
    return ref.watch(productsStreamProvider).when(
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => Text('خطأ: $e'),
      data: (products) {
        if (_outputs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('لم يتم إضافة أي أصناف بعد')));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _outputs.length,
          itemBuilder: (context, index) {
            final output = _outputs[index];
            final product = products.firstWhere((p) => p.id == output.productId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('صافي: ${output.quantity} كغ (${output.basketCount} سلال)'),
                trailing: Text('${output.yieldPercentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.blue)),
                leading: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => _outputs.removeAt(index)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortingSummary() {
    final sortedTotal = _outputs.fold<double>(0, (sum, i) => sum + i.quantity);
    final remaining = (_slaughterNetWeight - sortedTotal).clamp(0, double.infinity);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _summaryRow('إجمالي وزن الأصناف المفرزة:', '${sortedTotal.toStringAsFixed(2)} كغ'),
          _summaryRow('المتبقي للتوزيع (فائض):', '${remaining.toStringAsFixed(2)} كغ', isRed: remaining > 0.1),
          if (remaining > 0.1) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddSurplusDialog(remaining),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('تخزين المتبقي كدجاج كامل (فائض)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSurplusDialog(double remainingWeight) {
    Product? selectedProduct;
    // Try to find a product named "كامل" or "Whole"
    ref.read(productsStreamProvider).whenData((products) {
      try {
        selectedProduct = products.firstWhere(
          (p) => p.name.contains('كامل') || p.name.toLowerCase().contains('whole'),
        );
      } catch (_) {}
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تخزين الفائض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سيتم إضافة $remainingWeight كغ إلى المخزون كأصناف جاهزة للبيع.'),
            const SizedBox(height: 16),
            ref.watch(productsStreamProvider).when(
              data: (prods) => DropdownButtonFormField<Product>(
                value: selectedProduct,
                decoration: const InputDecoration(labelText: 'صنف التخزين (دجاج كامل)'),
                items: prods.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (val) => selectedProduct = val,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('خطأ: $e'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (selectedProduct != null) {
                setState(() {
                  _outputs.add(ProcessingOutput(
                    processingId: 0, 
                    productId: selectedProduct!.id!,
                    quantity: remainingWeight,
                    yieldPercentage: _slaughterNetWeight > 0 ? (remainingWeight / _slaughterNetWeight) * 100 : 0,
                    // Surplus is usually just bulk, so we can use single basket or 0
                    basketCount: 0,
                    basketWeight: 0,
                    grossWeight: remainingWeight,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('تأكيد التخزين'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black)),
      ],
    );
  }

  void _showAddOutputDialog() {
    Product? selectedProduct;
    final grossController = TextEditingController();
    final countController = TextEditingController(text: '1');
    final tareController = TextEditingController(text: '0.6');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double calculateNet() {
            final gross = double.tryParse(grossController.text) ?? 0;
            final count = int.tryParse(countController.text) ?? 0;
            final tare = double.tryParse(tareController.text) ?? 0;
            return (gross - (count * tare)).clamp(0, double.infinity);
          }

          return AlertDialog(
            title: const Text('إضافة صنف مفروز'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ref.watch(productsStreamProvider).when(
                    data: (prods) => DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(labelText: 'اختر الصنف'),
                      items: prods.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (val) => selectedProduct = val,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('خطأ: $e'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: grossController,
                    decoration: const InputDecoration(labelText: 'الوزن القائم (صنف + سلال)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: countController,
                          decoration: const InputDecoration(labelText: 'عدد السلال', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: tareController,
                          decoration: const InputDecoration(labelText: 'وزن السلة', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50),
                    child: Text('الوزن الصافي للصنف: ${calculateNet().toStringAsFixed(2)} كغ', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final net = calculateNet();
                  if (selectedProduct != null && net > 0) {
                    setState(() {
                      _outputs.add(ProcessingOutput(
                        processingId: 0, 
                        productId: selectedProduct!.id!,
                        grossWeight: double.parse(grossController.text),
                        basketWeight: double.parse(tareController.text),
                        basketCount: int.parse(countController.text),
                        quantity: net,
                        yieldPercentage: _slaughterNetWeight > 0 ? (net / _slaughterNetWeight) * 100 : 0,
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveProcessing() async {
    if (_slaughterNetWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء التأكد من توزين الدجاج بعد الذبح')));
      return;
    }
    if (_outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة صنف مفرز واحد على الأقل')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(processingRepositoryProvider);
      final processing = RawMeatProcessing(
        batchNumber: 'P-${DateTime.now().millisecondsSinceEpoch}',
        liveGrossWeight: double.parse(_liveGrossController.text),
        liveCrateWeight: double.parse(_liveCrateWeightController.text),
        liveCrateCount: int.parse(_liveCrateCountController.text),
        liveNetWeight: _liveNetWeight,
        slaughteredGrossWeight: double.parse(_slaughterGrossController.text),
        slaughteredBasketWeight: double.parse(_slaughterBasketWeightController.text),
        slaughteredBasketCount: int.parse(_slaughterBasketCountController.text),
        slaughteredNetWeight: _slaughterNetWeight,
        netWeight: _slaughterNetWeight,
        totalCost: _totalCost,
        processingDate: DateTime.now(),
        createdBy: 1, // Default admin id
        notes: _notesController.text,
      );

      await repo.createProcessing(processing, _outputs);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل دورة التجهيز بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
