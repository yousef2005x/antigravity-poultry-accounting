import 'package:flutter/material.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/chart_of_accounts_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/journal_entries_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/trial_balance_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/balance_sheet_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/income_statement_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/account_ledger_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/credit_notes_screen.dart';

class AccountingHomeScreen extends StatelessWidget {
  const AccountingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النظام المحاسبي'),
        backgroundColor: Colors.blueAccent,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildCard(
            context,
            title: 'دليل الحسابات',
            icon: Icons.account_tree,
            color: Colors.teal,
            page: const ChartOfAccountsScreen(),
          ),
          _buildCard(
            context,
            title: 'القيود اليومية',
            icon: Icons.library_books,
            color: Colors.orange,
            page: const JournalEntriesScreen(),
          ),
          _buildCard(
            context,
            title: 'ميزان المراجعة',
            icon: Icons.balance,
            color: Colors.blue,
            page: const TrialBalanceScreen(),
          ),
          _buildCard(
            context,
            title: 'الميزانية العمومية',
            icon: Icons.account_balance,
            color: Colors.green,
            page: const BalanceSheetScreen(),
          ),
          _buildCard(
            context,
            title: 'قائمة الدخل',
            icon: Icons.trending_up,
            color: Colors.purple,
            page: const IncomeStatementScreen(),
          ),
          _buildCard(
            context,
            title: 'دفتر الأستاذ',
            icon: Icons.menu_book,
            color: Colors.brown,
            page: const AccountLedgerScreen(),
          ),
          _buildCard(
            context,
            title: 'الإشعارات الدائنة',
            icon: Icons.receipt_long,
            color: Colors.redAccent,
            page: const CreditNotesScreen(),
          ),
          _buildCard(
            context,
            title: 'مطابقة الحسابات',
            icon: Icons.handshake,
            color: Colors.indigo,
            page: null, // Placeholder for Reconciliation
            onTapPlaceholder: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('شاشة مطابقة الحسابات قيد التطوير')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    Widget? page,
    VoidCallback? onTapPlaceholder,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          } else if (onTapPlaceholder != null) {
            onTapPlaceholder();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
