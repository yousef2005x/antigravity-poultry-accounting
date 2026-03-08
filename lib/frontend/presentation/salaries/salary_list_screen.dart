import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'salary_form_screen.dart';

class SalaryListScreen extends ConsumerWidget {
  const SalaryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الرواتب'),
        backgroundColor: Colors.teal,
      ),
      body: ref.watch(salariesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (salaries) {
              if (salaries.isEmpty) {
                return const Center(child: Text('لا توجد رواتب مسجلة'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: salaries.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final salary = salaries[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade400,
                      child: const Icon(Icons.person_pin, color: Colors.white),
                    ),
                    title: Text(
                      salary.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (salary.notes != null && salary.notes!.isNotEmpty)
                          Text(salary.notes!),
                        Text(
                          'التاريخ: ${salary.salaryDate.day}/${salary.salaryDate.month}/${salary.salaryDate.year}',
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${salary.amount.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalaryFormScreen(salary: salary),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalaryFormScreen()),
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
