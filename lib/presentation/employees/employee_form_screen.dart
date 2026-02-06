import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/data/repositories/employee_repository_impl.dart';
import 'package:poultry_accounting/domain/entities/employee.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});
  final Employee? employee;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  DateTime _hireDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _salaryController = TextEditingController(
      text: widget.employee?.monthlySalary.toString() ?? '',
    );
    if (widget.employee != null) {
      _hireDate = widget.employee!.hireDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      id: widget.employee?.id,
      name: _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      monthlySalary: double.tryParse(_salaryController.text) ?? 0.0,
      hireDate: _hireDate,
    );

    try {
      final repo = ref.read(employeeRepositoryProvider);
      if (widget.employee == null) {
        await repo.createEmployee(employee);
      } else {
        await repo.updateEmployee(employee);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الموظف بنجاح')),
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
        title: Text(widget.employee == null ? 'إضافة موظف' : 'تعديل موظف'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الموظف *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'الراتب الشهري الثابت', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                 validator: (val) {
                  if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                    return 'أدخل رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تاريخ التعيين'),
                subtitle: Text('${_hireDate.year}-${_hireDate.month}-${_hireDate.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _hireDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _hireDate = picked);
                  }
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('حفظ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
