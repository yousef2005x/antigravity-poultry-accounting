import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/providers/accounting_provider.dart';
import 'package:poultry_accounting/backend/domain/entities/account.dart';

class AccountLedgerScreen extends ConsumerStatefulWidget {
  const AccountLedgerScreen({super.key});

  @override
  ConsumerState<AccountLedgerScreen> createState() => _AccountLedgerScreenState();
}

class _AccountLedgerScreenState extends ConsumerState<AccountLedgerScreen> {
  Account? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الأستاذ (حركة الحساب)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          _buildAccountSelector(),
          const Divider(height: 1),
          Expanded(
            child: _selectedAccount == null
                ? const Center(child: Text('الرجاء اختيار حساب لعرض حركته'))
                : _buildLedgerView(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: ref.watch(postableAccountsProvider).when(
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => Text('خطأ في تحميل الحسابات: $err'),
        data: (accounts) {
          return DropdownButtonFormField<Account>(
            decoration: const InputDecoration(
              labelText: 'اختر الحساب',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
            ),
            value: _selectedAccount,
            isExpanded: true,
            items: accounts.map((act) {
              return DropdownMenuItem(
                value: act,
                child: Text('${act.code} - ${act.name}'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAccount = val;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLedgerView() {
    return ref.watch(accountLedgerProvider(_selectedAccount!.code)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('لا توجد حركات مسجلة لهذا الحساب'));
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final dateFormat = DateFormat('yyyy/MM/dd');
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(entry.description),
                subtitle: Text('${dateFormat.format(entry.entryDate)} | القيد: ${entry.entryNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (entry.debit > 0)
                      Text('مدين: ${entry.debit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                    if (entry.credit > 0)
                      Text('دائن: ${entry.credit.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                    Text('الرصيد: ${entry.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
