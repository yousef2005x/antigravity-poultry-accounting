import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/expense.dart';
import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/data/database/database.dart' as db_file;
import 'package:drift/drift.dart' show Value;

class RawMeatProcessingScreen extends ConsumerStatefulWidget {
  const RawMeatProcessingScreen({super.key});

  @override
  ConsumerState<RawMeatProcessingScreen> createState() => _RawMeatProcessingScreenState();
}

class _RawMeatProcessingScreenState extends ConsumerState<RawMeatProcessingScreen> {
  // Note: FormKey is used implicitly in the Stepper for validation
  int _currentStep = 0;
  bool _isLoading = false;
  Supplier? _selectedSupplier;
  
  // Bug 5 Fix: Option to skip auto-purchase
  bool _skipAutoPurchase = false;
  
  // Bug 7 Fix: Store supplier future in state to avoid rebuilds
  late Future<List<Supplier>> _suppliersFuture;

  // Stage 1: Live
  final _liveGrossController = TextEditingController(text: '0');
  final _liveCrateWeightController = TextEditingController(text: '2.0'); // Default crate weight
  final _liveCrateCountController = TextEditingController(text: '0');
  final _pricePerKgController = TextEditingController(text: '0');
  
  // Stage 2: Slaughtered
  final _slaughterGrossController = TextEditingController(text: '0');
  final _slaughterBasketWeightController = TextEditingController(text: '0.6');
  final _slaughterBasketCountController = TextEditingController(text: '0');
  final _operationalExpensesController = TextEditingController(text: '0');

  // Stage 3: Sorted Outputs
  final List<ProcessingOutput> _outputs = [];
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Bug 7 Fix: Initialize supplier future once in initState
    _suppliersFuture = ref.read(supplierRepositoryProvider).getAllSuppliers();
  }

  @override
  void dispose() {
    _liveGrossController.dispose();
    _liveCrateWeightController.dispose();
    _liveCrateCountController.dispose();
    _pricePerKgController.dispose();
    _slaughterGrossController.dispose();
    _slaughterBasketWeightController.dispose();
    _slaughterBasketCountController.dispose();
    _operationalExpensesController.dispose();
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
  double get _operationalExpenses => double.tryParse(_operationalExpensesController.text) ?? 0;
  double get _totalSlaughteredCost => _totalCost + _operationalExpenses;
  double get _slaughteredUnitCost => _slaughterNetWeight > 0 ? (_totalSlaughteredCost / _slaughterNetWeight) : 0.0;

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
              if (_currentStep < 1) {
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
                          backgroundColor: _currentStep == 1 ? Colors.green : Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentStep == 1 ? 'تأكيد وحفظ الدورة' : 'التالي',
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
            ],
          ),
    );
  }

  Widget _buildLiveIntakeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupplierSelector(),
        const SizedBox(height: 16),
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

  Widget _buildSupplierSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            FutureBuilder<List<Supplier>>(
              // Bug 7 Fix: Use cached future
              future: _suppliersFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<Supplier>(
                  value: _selectedSupplier,
                  decoration: const InputDecoration(
                    labelText: 'اختر المورد',
                    prefixIcon: Icon(Icons.local_shipping),
                    border: InputBorder.none,
                  ),
                  items: snapshot.data!.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: _skipAutoPurchase ? null : (val) => setState(() => _selectedSupplier = val),
                );
              },
            ),
            // Bug 5 Fix: Option to skip auto-purchase
            CheckboxListTile(
              value: _skipAutoPurchase,
              onChanged: (val) => setState(() {
                _skipAutoPurchase = val ?? false;
                if (_skipAutoPurchase) _selectedSupplier = null;
              }),
              title: const Text('تخطي إنشاء فاتورة شراء', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('لن يتم إنشاء فاتورة شراء تلقائية (للتجهيز من مخزون موجود)'),
              secondary: const Icon(Icons.receipt_long),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
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
        TextFormField(
          controller: _operationalExpensesController,
          decoration: const InputDecoration(
            labelText: 'مصاريف تشغيلية (₪)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money_off),
            suffixText: '₪',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildSummaryBox('الوزن المذبوح الصافي', _slaughterNetWeight, 'كغ', Colors.green),
        const SizedBox(height: 8),
        _buildSummaryBox('إجمالي النقص (الهالك)', _shrinkageWeight, 'كغ', Colors.orange),
        const SizedBox(height: 8),
        _buildSummaryBox('تكلفة الجاج المذبوح (حي + مصاريف)', _totalSlaughteredCost, '₪', Colors.blue),
        const SizedBox(height: 8),
        _buildSummaryBox('تحويل التكلفة للكيلو (صافي)', _slaughteredUnitCost, '₪/كغ', Colors.indigo),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const ListTile(
            title: Text('تخزين تلقائي', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('سيتم تخزين كامل الكمية كـ "دجاج كامل" ليتم تقطيعه لاحقاً في قسم تحويل المخزون.'),
            leading: Icon(Icons.info_outline, color: Colors.blue),
          ),
        ),
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
        color: color.withValues(alpha: 0.1),
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






  Future<void> _saveProcessing() async {
    if (_slaughterNetWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء التأكد من توزين الدجاج بعد الذبح')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Automatically prepare whole chicken output
      await _prepareWholeChickenOutput();

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
        operationalExpenses: _operationalExpenses,
        processingDate: DateTime.now(),
        createdBy: 1, // TODO Bug 8: Replace with actual user ID from AuthProvider
        notes: _notesController.text,
      );

      final id = await repo.createProcessing(processing, _outputs);

      // Bug 5 Fix: Only create auto-purchase if not skipped and supplier selected
      if (!_skipAutoPurchase && _selectedSupplier != null) {
        await _createAutomaticPurchase(id, processing.batchNumber);
      }

      if (_operationalExpenses > 0) {
        await _logOperationalExpense(processing.batchNumber);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تسجيل دورة التجهيز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _prepareWholeChickenOutput() async {
    _outputs.clear();
    _outputs.add(ProcessingOutput(
      processingId: 0,
      productId: AppConstants.wholeChickenId,
      quantity: _slaughterNetWeight,
      yieldPercentage: 100,
      basketCount: int.tryParse(_slaughterBasketCountController.text) ?? 0,
      basketWeight: double.tryParse(_slaughterBasketWeightController.text) ?? 0,
      grossWeight: double.tryParse(_slaughterGrossController.text) ?? 0,
      inventoryDate: DateTime.now(),
    ),
  );
  }

  Future<void> _logOperationalExpense(String batchNumber) async {
    try {
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final categories = await expenseRepo.getAllCategories();
      
      int? categoryId = categories.where((c) => c.name.contains('ذبح') || c.name.contains('تقطيع') || c.name.contains('تشغيل')).firstOrNull?.id;
      
      if (categoryId == null) {
        categoryId = await expenseRepo.createCategory(const ExpenseCategory(name: 'مصاريف تقطيع وتشغيل'));
      }

      await expenseRepo.createExpense(Expense(
        categoryId: categoryId,
        amount: _operationalExpenses,
        expenseDate: DateTime.now(),
        description: 'مصاريف تشغيلية لدورة التجهيز: $batchNumber',
        notes: 'تم إنشاؤها تلقائياً من شاشة دورة التجهيز اليومية',
      ),);
    } catch (e) {
      debugPrint('Error auto-logging expense: $e');
    }
  }

  Future<void> _createAutomaticPurchase(int processingId, String batchNumber) async {
    try {
      final purchaseRepo = ref.read(purchaseRepositoryProvider);
      final productRepo = ref.read(productRepositoryProvider);
      
      final liveChicken = await productRepo.getProductById(AppConstants.liveChickenId);
      final invoiceNumber = 'AUTO-P-$processingId';
      
      final purchaseInvoice = PurchaseInvoice(
        invoiceNumber: invoiceNumber,
        supplierId: _selectedSupplier!.id!,
        invoiceDate: DateTime.now(),
        status: InvoiceStatus.confirmed,
        items: [
          PurchaseInvoiceItem(
            productId: AppConstants.liveChickenId,
            productName: liveChicken?.name ?? 'دجاج حي',
            quantity: _liveNetWeight,
            unitCost: double.tryParse(_pricePerKgController.text) ?? 0,
          ),
        ],
        notes: 'تم إنشاؤها تلقائياً من دورة التجهيز: $batchNumber',
      );

      final invId = await purchaseRepo.createPurchaseInvoice(purchaseInvoice);
      await purchaseRepo.confirmPurchaseInvoice(invId, 1); // Mock user 1
      
      // OPTIONAL: Mark the newly created inventory batch as consumed
      // Since processing is a conversion, the "Live Chicken" shouldn't stay in stock.
      await _consumeLiveInventory(invId);

    } catch (e) {
      debugPrint('Error creating automatic purchase: $e');
    }
  }

  Future<void> _consumeLiveInventory(int purchaseId) async {
    try {
      final appDb = ref.read(databaseProvider);
      // Update inventory batches created from this purchase to 0 remaining quantity
      await (appDb.update(appDb.inventoryBatches)..where((t) => t.purchaseInvoiceId.equals(purchaseId))).write(
        db_file.InventoryBatchesCompanion(
          remainingQuantity: Value(0),
        ),
      );
    } catch (e) {
      debugPrint('Error consuming live inventory: $e');
    }
  }
}
