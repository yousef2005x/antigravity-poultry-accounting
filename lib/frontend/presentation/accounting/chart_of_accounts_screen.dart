import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';
import 'package:poultry_accounting/backend/domain/entities/account.dart';

class ChartOfAccountsScreen extends ConsumerWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الحسابات'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(accountsStreamProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('لا يوجد حسابات بعد'));
          }

          // Group by root type
          final groupedAccounts = <String, List<Account>>{};
          for (final account in accounts) {
            groupedAccounts.putIfAbsent(account.rootType ?? 'Other', () => []).add(account);
          }

          return ListView.builder(
            itemCount: groupedAccounts.keys.length,
            itemBuilder: (context, index) {
              final rootType = groupedAccounts.keys.elementAt(index);
              final rootAccounts = groupedAccounts[rootType]!;
              
              return ExpansionTile(
                title: Text(
                  _translateRootType(rootType),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                initiallyExpanded: true,
                children: rootAccounts.map((account) {
                  return ListTile(
                    contentPadding: EdgeInsets.only(
                      right: account.isGroup ? 16.0 : 40.0,
                    ),
                    leading: account.isGroup
                        ? const Icon(Icons.folder, color: Colors.amber)
                        : const Icon(Icons.article, color: Colors.blueGrey),
                    title: Text(
                      '${account.code} - ${account.name}',
                      style: TextStyle(
                        fontWeight: account.isGroup ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(account.accountType),
                    trailing: account.isActive
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        : const Icon(Icons.cancel, color: Colors.red, size: 16),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add account form screen logic in the future
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('سيتم إضافة نموذج إنشاء حساب لاحقاً')),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _translateRootType(String rootType) {
    switch (rootType) {
      case 'Asset': return 'الأصول';
      case 'Liability': return 'الخصوم (الالتزامات)';
      case 'Equity': return 'حقوق الملكية';
      case 'Revenue': return 'الإيرادات';
      case 'Expense': return 'المصروفات';
      default: return rootType;
    }
  }
}
