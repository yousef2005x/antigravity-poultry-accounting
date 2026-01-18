import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/expense.dart';

class ExpenseCategoryListScreen extends ConsumerWidget {
  const ExpenseCategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصنيفات المصروفات'),
        backgroundColor: Colors.redAccent,
      ),
      body: ref.watch(expenseCategoriesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('لا توجد تصنيفات معرفة'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(category.description ?? 'لا يوجد وصف'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () => _showCategoryDialog(context, ref, category),
                    ),
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref, null),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, ExpenseCategory? category) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'إضافة تصنيف جديد' : 'تعديل تصنيف'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم التصنيف *'),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final newCategory = ExpenseCategory(
                id: category?.id,
                name: nameController.text,
                description: descController.text,
              );

              final repo = ref.read(expenseRepositoryProvider);
              if (category == null) {
                await repo.createCategory(newCategory);
              } else {
                await repo.updateCategory(newCategory);
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
