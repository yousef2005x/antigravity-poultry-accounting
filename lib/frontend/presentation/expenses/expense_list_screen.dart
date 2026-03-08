import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/expense.dart';

import 'expense_category_list_screen.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طھط£ظƒظٹط¯ ط§ظ„ط­ط°ظپ'),
        content: Text('ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯ ظ…ظ† ط­ط°ظپ ظ…طµط±ظˆظپ "${expense.description}"طں\nط³ظٹطھظ… ط£ظٹط¶ط§ظ‹ ط­ط°ظپ ط­ط±ظƒط© ط§ظ„طµظ†ط¯ظˆظ‚ ط§ظ„ظ…ط±طھط¨ط·ط© ط¨ظ‡.'),
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
        await ref.read(expenseRepositoryProvider).deleteExpense(expense.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('طھظ… ط­ط°ظپ ط§ظ„ظ…طµط±ظˆظپ ط¨ظ†ط¬ط§ط­')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ط°ظپ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ط³ط¬ظ„ ط§ظ„ظ…طµط±ظˆظپط§طھ'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseCategoryListScreen()),
            ),
            tooltip: 'طھطµظ†ظٹظپط§طھ ط§ظ„ظ…طµط§ط±ظٹظپ',
          ),
        ],
      ),
      body: ref.watch(expensesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ظ…طµط±ظˆظپط§طھ ظ…ط³ط¬ظ„ط©'));
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
                        Text('ط§ظ„طھطµظ†ظٹظپ: ${expense.categoryName ?? "ط؛ظٹط± ظ…طµظ†ظپ"}'),
                        Text(
                          'ط§ظ„طھط§ط±ظٹط®: ${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${expense.amount.toStringAsFixed(2)} â‚ھ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _confirmDelete(context, ref, expense),
                        ),
                      ],
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
