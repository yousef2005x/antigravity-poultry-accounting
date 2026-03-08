import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/expense.dart';

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
        const SnackBar(content: Text('ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± طھطµظ†ظٹظپ ط§ظ„ظ…طµط±ظˆظپ')),
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
          const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ظ…طµط±ظˆظپ ط¨ظ†ط¬ط§ط­')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ظپط¸: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طھط£ظƒظٹط¯ ط§ظ„ط­ط°ظپ'),
        content: const Text('ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯ ظ…ظ† ط­ط°ظپ ظ‡ط°ط§ ط§ظ„ظ…طµط±ظˆظپطں\nط³ظٹطھظ… ط£ظٹط¶ط§ظ‹ ط­ط°ظپ ط­ط±ظƒط© ط§ظ„طµظ†ط¯ظˆظ‚ ط§ظ„ظ…ط±طھط¨ط·ط© ط¨ظ‡.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ط¥ظ„ط؛ط§ط،'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ط­ط°ظپ'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(expenseRepositoryProvider).deleteExpense(widget.expense!.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('طھظ… ط­ط°ظپ ط§ظ„ظ…طµط±ظˆظپ ط¨ظ†ط¬ط§ط­')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ط°ظپ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'ط¥ط¶ط§ظپط© ظ…طµط±ظˆظپ' : 'طھط¹ط¯ظٹظ„ ظ…طµط±ظˆظپ'),
        backgroundColor: Colors.redAccent,
        actions: [
          if (widget.expense != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
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
                  labelText: 'ط§ظ„ظ…ط¨ظ„ط؛ (â‚ھ) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ظ„ظ…ط¨ظ„ط؛';
                  }
                  if (double.tryParse(val) == null) {
                    return 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط±ظ‚ظ… طµط­ظٹط­';
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
                  labelText: 'ط§ظ„ظˆطµظپ / ط§ظ„ط¨ظٹط§ظ† *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ظ„ظˆطµظپ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ظ…ظ„ط§ط­ط¸ط§طھ ط¥ط¶ط§ظپظٹط©',
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
                  child: const Text('ط­ظپط¸ ط§ظ„ظ…طµط±ظˆظپ', style: TextStyle(fontSize: 18)),
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
          error: (err, stack) => Text('ط®ط·ط£ ظپظٹ طھط­ظ…ظٹظ„ ط§ظ„طھطµظ†ظٹظپط§طھ: $err'),
          data: (categories) {
            return DropdownButtonFormField<int>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'ط§ظ„طھطµظ†ظٹظپ *',
                border: OutlineInputBorder(),
              ),
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              validator: (val) => val == null ? 'ظٹط±ط¬ظ‰ ط§ط®طھظٹط§ط± ط§ظ„طھطµظ†ظٹظپ' : null,
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
          labelText: 'ط§ظ„طھط§ط±ظٹط®',
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
