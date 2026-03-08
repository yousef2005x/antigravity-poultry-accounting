import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/auth_provider.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/frontend/presentation/admin/settings_screen.dart';
import 'package:poultry_accounting/frontend/presentation/annual_returns/annual_inventories_screen.dart';
import 'package:poultry_accounting/frontend/presentation/customers/customer_management_screen.dart';
import 'package:poultry_accounting/frontend/presentation/expenses/expense_list_screen.dart';
import 'package:poultry_accounting/frontend/presentation/inventory/stock_dashboard_screen.dart';
import 'package:poultry_accounting/frontend/presentation/partnership/partnership_screen.dart';
import 'package:poultry_accounting/frontend/presentation/pricing/daily_pricing_screen.dart';
import 'package:poultry_accounting/frontend/presentation/processing/raw_meat_processing_screen.dart';
import 'package:poultry_accounting/frontend/presentation/processing/stock_conversion_screen.dart';
import 'package:poultry_accounting/frontend/presentation/products/product_list_screen.dart';
import 'package:poultry_accounting/frontend/presentation/purchases/purchase_list_screen.dart';
import 'package:poultry_accounting/frontend/presentation/reports/central_debt_register_screen.dart';
import 'package:poultry_accounting/frontend/presentation/reports/reports_screen.dart';
import 'package:poultry_accounting/frontend/presentation/salaries/salary_list_screen.dart';
import 'package:poultry_accounting/frontend/presentation/salaries/salary_statement_screen.dart';
import 'package:poultry_accounting/frontend/presentation/sales/sales_management_screen.dart';
import 'package:poultry_accounting/frontend/presentation/suppliers/supplier_management_screen.dart';
import 'package:poultry_accounting/frontend/presentation/employees/employee_list_screen.dart';
import 'package:poultry_accounting/frontend/presentation/settings/reset_database_screen.dart';
import 'package:poultry_accounting/frontend/presentation/home/home_screen.dart';
import 'package:poultry_accounting/frontend/presentation/accounting/accounting_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ظ†ط¸ط§ظ… ظ…ط­ط§ط³ط¨ط© ط§ظ„ط¯ظˆط§ط¬ظ† - ظ„ظˆط­ط© ط§ظ„طھط­ظƒظ…'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.account_balance,
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 35),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ظ†ط¸ط§ظ… ط§ظ„ط¯ظˆط§ط¬ظ†',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ref.watch(authProvider).user?.fullName ?? 'ط§ظ„ظ…ط³ط¤ظˆظ„',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(Icons.dashboard, 'ظ„ظˆط­ط© ط§ظ„طھط­ظƒظ…', () {
                    Navigator.pop(context);
                  }),
                  const Divider(height: 8),
                  
                  // ط§ظ„ط¹ظ…ظ„ط§ط،
                  _buildDrawerItem(
                    Icons.people,
                    'ط§ظ„ط¹ظ…ظ„ط§ط،',
                    () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerManagementScreen()));
                    },
                    color: Colors.blue,
                  ),

                  // ط§ظ„ظ…ظˆط±ط¯ظٹظ†
                  _buildDrawerItem(
                    Icons.business,
                    'ط§ظ„ظ…ظˆط±ط¯ظٹظ†',
                    () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierManagementScreen()));
                    },
                    color: Colors.orange,
                  ),

                  // ط§ظ„ظ…ط¨ظٹط¹ط§طھ ظˆط§ظ„طھط­طµظٹظ„
                  _buildDrawerItem(
                    Icons.point_of_sale,
                    'ط§ظ„ظ…ط¨ظٹط¹ط§طھ ظˆط§ظ„طھط­طµظٹظ„',
                    () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesManagementScreen()));
                    },
                    color: Colors.green,
                  ),

                  const Divider(height: 8),

                  // النظام المحاسبي
                  _buildDrawerItem(
                    Icons.account_balance,
                    'النظام المحاسبي',
                    () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountingHomeScreen()));
                    },
                    color: Colors.blueAccent,
                  ),

                  // ط§ظ„ظ…ط®ط²ظˆظ† ظˆط§ظ„ظˆط§ط±ط¯ط§طھ
                  _buildExpansionTile(
                    Icons.inventory_2, 
                    'ط§ظ„ظ…ط®ط²ظˆظ† ظˆط§ظ„ظˆط§ط±ط¯ط§طھ', 
                    [
                      _buildDrawerItem(Icons.inventory, 'ظ„ظˆط­ط© ط§ظ„ظ…ط®ط²ظˆظ†', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDashboardScreen()));
                      }),
                      _buildDrawerItem(Icons.shopping_bag, 'ط§ظ„ظ…ظ†طھط¬ط§طھ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                      }),
                      _buildDrawerItem(Icons.shopping_cart, 'ط§ظ„ظˆط§ط±ط¯ط§طھ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen()));
                      }),
                      _buildDrawerItem(Icons.price_check, 'ط§ظ„طھط³ط¹ظٹط± ط§ظ„ظٹظˆظ…ظٹ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyPricingScreen()));
                      }),
                    ],
                    iconColor: Colors.purple,
                  ),

                  // ط§ظ„ظ…طµط±ظˆظپط§طھ ط§ظ„ظ…ط§ظ„ظٹط©
                  _buildExpansionTile(
                    Icons.account_balance_wallet, 
                    'ط§ظ„ظ…طµط±ظˆظپط§طھ ط§ظ„ظ…ط§ظ„ظٹط©', 
                    [
                      _buildDrawerItem(Icons.money_off, 'ط§ظ„ظ…طµط±ظˆظپط§طھ ط§ظ„طھط´ط؛ظٹظ„ظٹط©', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                      }),

                      _buildDrawerItem(Icons.attach_money, 'ط§ظ„ط±ظˆط§طھط¨ ظˆط§ظ„ط£ط¬ظˆط±', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryStatementScreen()));
                      }),
                      _buildDrawerItem(Icons.people_alt, 'ط¥ط¯ط§ط±ط© ط§ظ„ظ…ظˆط¸ظپظٹظ†', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
                      }),
                    ],
                    iconColor: Colors.red.shade700,
                  ),

                  // ط§ظ„طھظ‚ط§ط±ظٹط± ظˆط§ظ„ظ…ط§ظ„ظٹط©
                  _buildExpansionTile(
                    Icons.analytics, 
                    'ط§ظ„طھظ‚ط§ط±ظٹط± ظˆط§ظ„ظ…ط§ظ„ظٹط©', 
                    [
                      _buildDrawerItem(Icons.bar_chart, 'ط§ظ„طھظ‚ط§ط±ظٹط± ط§ظ„طھط­ظ„ظٹظ„ظٹط©', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      }),
                      _buildDrawerItem(Icons.account_balance, 'ط³ط¬ظ„ ط§ظ„ط¯ظٹظˆظ† ط§ظ„ظ…ظˆط­ط¯', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CentralDebtRegisterScreen()));
                      }),
                      _buildDrawerItem(Icons.event_repeat, 'ط§ظ„ط¬ط±ط¯ ط§ظ„ط³ظ†ظˆظٹ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnualInventoriesScreen()));
                      }),
                      _buildDrawerItem(Icons.handshake, 'ط£ط±ط¨ط§ط­ ط§ظ„ط´ط±ظƒط§ط،', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnershipScreen()));
                      }),
                    ],
                    iconColor: Colors.teal,
                  ),

                  // ط§ظ„ط¥ط¯ط§ط±ط© ظˆط§ظ„ظ†ط¸ط§ظ…
                  _buildExpansionTile(
                    Icons.settings, 
                    'ط§ظ„ط¥ط¯ط§ط±ط© ظˆط§ظ„ظ†ط¸ط§ظ…', 
                    [
                      _buildDrawerItem(Icons.calculate, 'طھط¬ظ‡ظٹط² ط§ظ„ط®ط§ظ…', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RawMeatProcessingScreen()));
                      }),
                      _buildDrawerItem(Icons.cut, 'طھط­ظˆظٹظ„ ط§ظ„ظ…ط®ط²ظˆظ†', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockConversionScreen()));
                      }),
                      _buildDrawerItem(Icons.settings_applications, 'ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      }),
                      _buildDrawerItem(Icons.delete_forever, 'طھطµظپظٹط± ظ‚ط§ط¹ط¯ط© ط§ظ„ط¨ظٹط§ظ†ط§طھ', () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetDatabaseScreen()));
                      }, color: Colors.red),
                    ],
                    iconColor: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.red.shade50,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'طھط³ط¬ظٹظ„ ط§ظ„ط®ط±ظˆط¬',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ظ†ط¸ط±ط© ط¹ط§ظ…ط© (ط§ظ„ظٹظˆظ…)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            metricsAsync.when(
              data: (data) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(
                        'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ظ…ط¨ظٹط¹ط§طھ', 
                        '${data.todaySales.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesManagementScreen())),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(
                        'ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„طھط­طµظٹظ„', 
                        '${data.todayReceipts.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(
                        'ط§ظ„ط°ظ…ظ… ط§ظ„ظ…ط³طھط­ظ‚ط©', 
                        '${data.totalOutstanding.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CentralDebtRegisterScreen())),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(
                        'ط§ظ„ظ…طµط±ظˆظپط§طھ', 
                        '${data.todayExpenses.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen())),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(
                        'ط§ظ„ظˆط§ط±ط¯ط§طھ (ط§ظ„ظ…ط´طھط±ظٹط§طھ)', 
                        '${data.todayPurchases.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.deepPurple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen())),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(
                        'ط§ظ„ط±ظˆط§طھط¨', 
                        '${data.todaySalaries.toStringAsFixed(2)} ط´ظٹظƒظ„', 
                        Colors.brown,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryStatementScreen())),
                      )),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('ط®ط·ط£ ظپظٹ طھط­ظ…ظٹظ„ ط§ظ„ط¨ظٹط§ظ†ط§طھ: $err')),
            ),
            const SizedBox(height: 30),
            const Text(
              'ط¢ط®ط± ط§ظ„ظپظˆط§طھظٹط±',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const Text('ظ„ط§ طھظˆط¬ط¯ ظپظˆط§طھظٹط± ط­ط¯ظٹط«ط©');
                }
                // Take last 5 invoices
                final recentInvoices = invoices.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentInvoices.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = recentInvoices[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text('ظپط§طھظˆط±ط© ط±ظ‚ظ… #${invoice.id}'), // Or use invoiceNumber if available
                      subtitle: Text('ط§ظ„طھط§ط±ظٹط®: ${invoice.invoiceDate.toString().split(' ')[0]}'),
                      trailing: Text(
                        '${invoice.total.toStringAsFixed(2)} ط´ظٹظƒظ„',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('ط®ط·ط£: $err'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesManagementScreen()));
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('ظپط§طھظˆط±ط© ط¬ط¯ظٹط¯ط©'),
      ),
    );
  }

  Widget _buildExpansionTile(IconData icon, String title, List<Widget> children, {Color? iconColor}) {
    final color = iconColor ?? Colors.green.shade800;
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        iconColor: color,
        childrenPadding: const EdgeInsets.only(right: 12),
        children: children,
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: color ?? Colors.green.shade600, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        hoverColor: Colors.green.shade50,
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
