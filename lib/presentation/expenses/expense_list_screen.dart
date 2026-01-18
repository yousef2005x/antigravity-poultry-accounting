import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';

import 'expense_category_list_screen.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المصروفات'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseCategoryListScreen()),
            ),
            tooltip: 'تصنيفات المصاريف',
          ),
        ],
      ),
      body: ref.watch(expensesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('لا توجد مصروفات مسجلة'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade400,
                      child: const Icon(Icons.money_off, color: Colors.white),
                    ),
                    title: Text(
                      expense.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التصنيف: ${expense.categoryName ?? "غير مصنف"}'),
                        Text(
                          'التاريخ: ${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${expense.amount.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseFormScreen(expense: expense),
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
          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
        ),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
