import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/annual_inventory.dart';

class AnnualInventoryFormScreen extends ConsumerStatefulWidget {
  const AnnualInventoryFormScreen({super.key, this.annualInventory});
  final AnnualInventory? annualInventory;

  @override
  ConsumerState<AnnualInventoryFormScreen> createState() => _AnnualInventoryFormScreenState();
}

class _AnnualInventoryFormScreenState extends ConsumerState<AnnualInventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descController;
  DateTime _inventoryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.annualInventory?.amount.toString() ?? '',
    );
    _descController = TextEditingController(text: widget.annualInventory?.description ?? '');
    if (widget.annualInventory != null) {
      _inventoryDate = widget.annualInventory!.inventoryDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = AnnualInventory(
      id: widget.annualInventory?.id,
      amount: double.parse(_amountController.text),
      inventoryDate: _inventoryDate,
      description: _descController.text,
    );

    try {
      final repo = ref.read(annualInventoryRepositoryProvider);
      if (widget.annualInventory == null) {
        await repo.createInventory(item);
      } else {
        await repo.updateInventory(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تسوية الجرد بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.annualInventory == null ? 'إضافة تسوية جرد' : 'تعديل تسوية'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (₪) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  if (double.tryParse(val) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'الوصف / البيان *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال الوصف' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ التسوية', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _inventoryDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _inventoryDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_inventoryDate.day}/${_inventoryDate.month}/${_inventoryDate.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
