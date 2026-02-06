import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/data/repositories/employee_repository_impl.dart';
import 'package:poultry_accounting/presentation/employees/employee_form_screen.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الموظفين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
            ),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('لا يوجد موظفين مسجلين'));
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return ListTile(
                title: Text(employee.name),
                subtitle: Text('الراتب: ${employee.monthlySalary} ₪'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeFormScreen(employee: employee),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                         // Confirm delete dialog
                         showDialog(context: context, builder: (ctx) => AlertDialog(
                           title: const Text('حذف الموظف'),
                           content: const Text('هل أنت متأكد؟'),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                             TextButton(onPressed: () async {
                               Navigator.pop(ctx);
                               await ref.read(employeeRepositoryProvider).deleteEmployee(employee.id!);
                             }, child: const Text('حذف')),
                           ],
                         ));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
