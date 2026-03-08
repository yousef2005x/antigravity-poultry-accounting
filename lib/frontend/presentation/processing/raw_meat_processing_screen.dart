import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/expense.dart';
import 'package:poultry_accounting/backend/domain/entities/processing_output.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';
import 'package:poultry_accounting/backend/domain/entities/raw_meat_processing.dart';
import 'package:poultry_accounting/backend/domain/entities/supplier.dart';
import 'package:poultry_accounting/backend/domain/entities/purchase_invoice.dart';
import 'package:poultry_accounting/backend/data/database/database.dart' as db_file;
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
        title: const Text('ط¯ظˆط±ط© ط§ظ„طھط¬ظ‡ظٹط² ط§ظ„ظٹظˆظ…ظٹط©'),
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
                          _currentStep == 1 ? 'طھط£ظƒظٹط¯ ظˆط­ظپط¸ ط§ظ„ط¯ظˆط±ط©' : 'ط§ظ„طھط§ظ„ظٹ',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep == 0 ? 'ط¥ظ„ط؛ط§ط،' : 'ط§ظ„ط³ط§ط¨ظ‚'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('ط¯ط¬ط§ط¬ ط±ظٹط´'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.editing,
                content: _buildLiveIntakeSection(),
              ),
              Step(
                title: const Text('ط¨ط¹ط¯ ط§ظ„ط°ط¨ط­'),
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
        _buildInfoCard('طھظˆط²ظٹظ† ط§ظ„ط¯ط¬ط§ط¬ ط§ظ„ط­ظٹ (ظپظٹ ط§ظ„طµظ†ط§ط¯ظٹظ‚)'),
        const SizedBox(height: 16),
        _buildWeightInputRow(
          grossController: _liveGrossController,
          countController: _liveCrateCountController,
          tareController: _liveCrateWeightController,
          grossLabel: 'ط§ظ„ظˆط²ظ† ط§ظ„ظ‚ط§ط¦ظ… (ط±ظٹط´ + طµظ†ط§ط¯ظٹظ‚)',
          countLabel: 'ط¹ط¯ط¯ ط§ظ„طµظ†ط§ط¯ظٹظ‚',
          tareLabel: 'ظˆط²ظ† ط§ظ„طµظ†ط¯ظˆظ‚ ط§ظ„ظپط§ط±ط؛',
        ),
        const SizedBox(height: 16),
        _buildPriceAndCostSection(),
        const SizedBox(height: 16),
        _buildSummaryBox('ط§ظ„ظˆط²ظ† ط§ظ„ط­ظٹ ط§ظ„طµط§ظپظٹ', _liveNetWeight, 'ظƒط؛', Colors.indigo),
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
                    labelText: 'ط§ط®طھط± ط§ظ„ظ…ظˆط±ط¯',
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
              title: const Text('طھط®ط·ظٹ ط¥ظ†ط´ط§ط، ظپط§طھظˆط±ط© ط´ط±ط§ط،', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('ظ„ظ† ظٹطھظ… ط¥ظ†ط´ط§ط، ظپط§طھظˆط±ط© ط´ط±ط§ط، طھظ„ظ‚ط§ط¦ظٹط© (ظ„ظ„طھط¬ظ‡ظٹط² ظ…ظ† ظ…ط®ط²ظˆظ† ظ…ظˆط¬ظˆط¯)'),
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
        _buildInfoCard('طھظˆط²ظٹظ† ط§ظ„ط¯ط¬ط§ط¬ ط¨ط¹ط¯ ط§ظ„ط°ط¨ط­ ظˆط§ظ„طھظ†ط¸ظٹظپ (ظپظٹ ط§ظ„ط³ظ„ط§ظ„)'),
        const SizedBox(height: 16),
        _buildWeightInputRow(
          grossController: _slaughterGrossController,
          countController: _slaughterBasketCountController,
          tareController: _slaughterBasketWeightController,
          grossLabel: 'ط§ظ„ظˆط²ظ† ط§ظ„ظ‚ط§ط¦ظ… (ظ…ط°ط¨ظˆط­ + ط³ظ„ط§ظ„)',
          countLabel: 'ط¹ط¯ط¯ ط§ظ„ط³ظ„ط§ظ„',
          tareLabel: 'ظˆط²ظ† ط§ظ„ط³ظ„ط© ط§ظ„ظپط§ط±ط؛ط©',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _operationalExpensesController,
          decoration: const InputDecoration(
            labelText: 'ظ…طµط§ط±ظٹظپ طھط´ط؛ظٹظ„ظٹط© (â‚ھ)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money_off),
            suffixText: 'â‚ھ',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildSummaryBox('ط§ظ„ظˆط²ظ† ط§ظ„ظ…ط°ط¨ظˆط­ ط§ظ„طµط§ظپظٹ', _slaughterNetWeight, 'ظƒط؛', Colors.green),
        const SizedBox(height: 8),
        _buildSummaryBox('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ†ظ‚طµ (ط§ظ„ظ‡ط§ظ„ظƒ)', _shrinkageWeight, 'ظƒط؛', Colors.orange),
        const SizedBox(height: 8),
        _buildSummaryBox('طھظƒظ„ظپط© ط§ظ„ط¬ط§ط¬ ط§ظ„ظ…ط°ط¨ظˆط­ (ط­ظٹ + ظ…طµط§ط±ظٹظپ)', _totalSlaughteredCost, 'â‚ھ', Colors.blue),
        const SizedBox(height: 8),
        _buildSummaryBox('طھط­ظˆظٹظ„ ط§ظ„طھظƒظ„ظپط© ظ„ظ„ظƒظٹظ„ظˆ (طµط§ظپظٹ)', _slaughteredUnitCost, 'â‚ھ/ظƒط؛', Colors.indigo),
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
            title: Text('طھط®ط²ظٹظ† طھظ„ظ‚ط§ط¦ظٹ', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ط³ظٹطھظ… طھط®ط²ظٹظ† ظƒط§ظ…ظ„ ط§ظ„ظƒظ…ظٹط© ظƒظ€ "ط¯ط¬ط§ط¬ ظƒط§ظ…ظ„" ظ„ظٹطھظ… طھظ‚ط·ظٹط¹ظ‡ ظ„ط§ط­ظ‚ط§ظ‹ ظپظٹ ظ‚ط³ظ… طھط­ظˆظٹظ„ ط§ظ„ظ…ط®ط²ظˆظ†.'),
            leading: Icon(Icons.info_outline, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'ظ…ظ„ط§ط­ط¸ط§طھ ط¥ط¶ط§ظپظٹط©', border: OutlineInputBorder()),
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
            decoration: const InputDecoration(labelText: 'ط³ط¹ط± ط´ط±ط§ط، ط§ظ„ط­ظٹ ظ„ظ„ظƒظٹظ„ظˆ', border: OutlineInputBorder(), suffixText: 'â‚ھ'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryBox('ط¥ط¬ظ…ط§ظ„ظٹ طھظƒظ„ظپط© ط§ظ„ط´ط±ط§ط،', _totalCost, 'â‚ھ', Colors.blue),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ط§ظ„ط±ط¬ط§ط، ط§ظ„طھط£ظƒط¯ ظ…ظ† طھظˆط²ظٹظ† ط§ظ„ط¯ط¬ط§ط¬ ط¨ط¹ط¯ ط§ظ„ط°ط¨ط­')));
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
          content: Text('طھظ… طھط³ط¬ظٹظ„ ط¯ظˆط±ط© ط§ظ„طھط¬ظ‡ظٹط² ط¨ظ†ط¬ط§ط­'),
          behavior: SnackBarBehavior.floating,
        ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ط­ط¯ط« ط®ط·ط£ ط£ط«ظ†ط§ط، ط§ظ„ط­ظپط¸: $e')));
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
      
      int? categoryId = categories.where((c) => c.name.contains('ط°ط¨ط­') || c.name.contains('طھظ‚ط·ظٹط¹') || c.name.contains('طھط´ط؛ظٹظ„')).firstOrNull?.id;
      
      if (categoryId == null) {
        categoryId = await expenseRepo.createCategory(const ExpenseCategory(name: 'ظ…طµط§ط±ظٹظپ طھظ‚ط·ظٹط¹ ظˆطھط´ط؛ظٹظ„'));
      }

      await expenseRepo.createExpense(Expense(
        categoryId: categoryId,
        amount: _operationalExpenses,
        expenseDate: DateTime.now(),
        description: 'ظ…طµط§ط±ظٹظپ طھط´ط؛ظٹظ„ظٹط© ظ„ط¯ظˆط±ط© ط§ظ„طھط¬ظ‡ظٹط²: $batchNumber',
        notes: 'طھظ… ط¥ظ†ط´ط§ط¤ظ‡ط§ طھظ„ظ‚ط§ط¦ظٹط§ظ‹ ظ…ظ† ط´ط§ط´ط© ط¯ظˆط±ط© ط§ظ„طھط¬ظ‡ظٹط² ط§ظ„ظٹظˆظ…ظٹط©',
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
            productName: liveChicken?.name ?? 'ط¯ط¬ط§ط¬ ط­ظٹ',
            quantity: _liveNetWeight,
            unitCost: double.tryParse(_pricePerKgController.text) ?? 0,
          ),
        ],
        notes: 'طھظ… ط¥ظ†ط´ط§ط¤ظ‡ط§ طھظ„ظ‚ط§ط¦ظٹط§ظ‹ ظ…ظ† ط¯ظˆط±ط© ط§ظ„طھط¬ظ‡ظٹط²: $batchNumber',
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
