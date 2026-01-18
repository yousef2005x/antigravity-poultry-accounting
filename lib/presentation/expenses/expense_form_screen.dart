import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/expense.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});
  final Expense? expense;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late TextEditingController _notesController;
  int? _selectedCategoryId;
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _descController = TextEditingController(text: widget.expense?.description ?? '');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _selectedCategoryId = widget.expense?.categoryId;
    if (widget.expense != null) {
      _expenseDate = widget.expense!.expenseDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تصنيف المصروف')),
      );
      return;
    }

    final expense = Expense(
      id: widget.expense?.id,
      categoryId: _selectedCategoryId!,
      amount: double.parse(_amountController.text),
      expenseDate: _expenseDate,
      description: _descController.text,
      notes: _notesController.text,
    );

    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (widget.expense == null) {
        await repo.createExpense(expense);
      } else {
        await repo.updateExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المصروف بنجاح')),
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
        title: Text(widget.expense == null ? 'إضافة مصروف' : 'تعديل مصروف'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ المصروف', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return ref.watch(expenseCategoriesStreamProvider).when(
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text('خطأ في تحميل التصنيفات: $err'),
          data: (categories) {
            return DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'التصنيف *',
                border: OutlineInputBorder(),
              ),
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              validator: (val) => val == null ? 'يرجى اختيار التصنيف' : null,
            );
          },
        );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _expenseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _expenseDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
