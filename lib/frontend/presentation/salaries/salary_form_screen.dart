import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/data/repositories/employee_repository_impl.dart';
import 'package:poultry_accounting/backend/domain/entities/salary.dart';

class SalaryFormScreen extends ConsumerStatefulWidget {
  const SalaryFormScreen({super.key, this.salary});
  final Salary? salary;

  @override
  ConsumerState<SalaryFormScreen> createState() => _SalaryFormScreenState();
}

class _SalaryFormScreenState extends ConsumerState<SalaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  DateTime _salaryDate = DateTime.now();
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.salary?.amount.toString() ?? '',
    );
    _nameController = TextEditingController(text: widget.salary?.employeeName ?? '');
    _notesController = TextEditingController(text: widget.salary?.notes ?? '');
    if (widget.salary != null) {
      _salaryDate = widget.salary!.salaryDate;
      _selectedEmployeeId = widget.salary!.employeeId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final salary = Salary(
      id: widget.salary?.id,
      amount: double.parse(_amountController.text),
      salaryDate: _salaryDate,
      employeeName: _nameController.text,
      employeeId: _selectedEmployeeId,
      notes: _notesController.text,
    );

    try {
      final repo = ref.read(salaryRepositoryProvider);
      if (widget.salary == null || widget.salary!.id == null) {
        await repo.createSalary(salary);
      } else {
        await repo.updateSalary(salary);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('طھظ… ط­ظپط¸ ط§ظ„ط±ط§طھط¨ ط¨ظ†ط¬ط§ط­')),
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

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final isEditing = widget.salary != null && widget.salary!.id != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'طھط¹ط¯ظٹظ„ ط±ط§طھط¨' : 'طµط±ظپ ط±ط§طھط¨'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Selection
              employeesAsync.when(
                data: (employees) {
                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       DropdownButtonFormField<int>(
                         value: _selectedEmployeeId,
                         decoration: const InputDecoration(
                           labelText: 'ط§ط®طھط± ط§ظ„ظ…ظˆط¸ظپ',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.person),
                         ),
                         items: [
                           ...employees.map((e) => DropdownMenuItem(
                             value: e.id,
                             child: Text('${e.name} (${e.monthlySalary} ط´ظٹظƒظ„)'),
                           )),
                         ],
                         onChanged: (id) {
                           setState(() {
                             _selectedEmployeeId = id;
                             if (id != null) {
                               final emp = employees.firstWhere((e) => e.id == id);
                               _nameController.text = emp.name;
                             }
                           });
                         },
                         validator: (val) => val == null && _nameController.text.isEmpty ? 'ط§ط®طھط± ظ…ظˆط¸ظپط§ظ‹ ط£ظˆ ط§ط¯ط®ظ„ ط§ظ„ط§ط³ظ…' : null,
                       ),
// ... lines continue ...
                     ],
                   );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('ط®ط·ط£ ظپظٹ طھط­ظ…ظٹظ„ ط§ظ„ظ…ظˆط¸ظپظٹظ†: $e'),
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'ط§ظ„ظ…ط¨ظ„ط؛ (ط´ظٹظƒظ„) *',
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
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ط­ظپط¸ ط§ظ„ط¨ظٹط§ظ†ط§طھ', style: TextStyle(fontSize: 18)),
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
          initialDate: _salaryDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() => _salaryDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'ط§ظ„طھط§ط±ظٹط®',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_salaryDate.day}/${_salaryDate.month}/${_salaryDate.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
