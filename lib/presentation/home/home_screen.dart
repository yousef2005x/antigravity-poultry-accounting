import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/presentation/admin/settings_screen.dart';
import 'package:poultry_accounting/presentation/customers/customer_management_screen.dart';
import 'package:poultry_accounting/presentation/suppliers/supplier_management_screen.dart';
import 'package:poultry_accounting/presentation/sales/sales_management_screen.dart';
import 'package:poultry_accounting/presentation/expenses/expense_list_screen.dart';
import 'package:poultry_accounting/presentation/inventory/stock_dashboard_screen.dart';
import 'package:poultry_accounting/presentation/partnership/partnership_screen.dart';
import 'package:poultry_accounting/presentation/payments/payment_list_screen.dart';
import 'package:poultry_accounting/presentation/pricing/daily_pricing_screen.dart';
import 'package:poultry_accounting/presentation/processing/raw_meat_processing_screen.dart';
import 'package:poultry_accounting/presentation/processing/stock_conversion_screen.dart';
import 'package:poultry_accounting/presentation/products/product_list_screen.dart';
import 'package:poultry_accounting/presentation/purchases/purchase_list_screen.dart';
import 'package:poultry_accounting/presentation/pricing/daily_pricing_screen.dart';
import 'package:poultry_accounting/presentation/pricing/live_chicken_pricing_screen.dart';
import 'package:poultry_accounting/presentation/reports/central_debt_register_screen.dart';
import 'package:poultry_accounting/presentation/reports/reports_screen.dart';

import 'package:poultry_accounting/presentation/annual_returns/annual_inventories_screen.dart';
import 'package:poultry_accounting/presentation/salaries/salary_list_screen.dart';

import 'package:poultry_accounting/core/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsFuture = ref.watch(reportRepositoryProvider).getDashboardMetrics();
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام محاسبة الدواجن - لوحة التحكم'),
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
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                          'نظام الدواجن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ref.watch(authProvider).user?.fullName ?? 'المسؤول',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
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
                  _buildDrawerItem(Icons.dashboard, 'لوحة التحكم', () {
                    Navigator.pop(context);
                  }),
                  const Divider(height: 8),
                  
                  // العملاء
                  _buildDrawerItem(Icons.people, 'العملاء', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerManagementScreen()));
                  }, color: Colors.blue),

                  // الموردين
                  _buildDrawerItem(Icons.business, 'الموردين', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierManagementScreen()));
                  }, color: Colors.orange),

                  // المبيعات والتحصيل
                  _buildDrawerItem(Icons.point_of_sale, 'المبيعات والتحصيل', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesManagementScreen()));
                  }, color: Colors.green),

                  const Divider(height: 8),

                  // المخزون والواردات
                  _buildExpansionTile(
                    Icons.inventory_2, 
                    'المخزون والواردات', 
                    [
                      _buildDrawerItem(Icons.inventory, 'لوحة المخزون', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDashboardScreen()));
                      }),
                      _buildDrawerItem(Icons.shopping_bag, 'المنتجات', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                      }),
                      _buildDrawerItem(Icons.shopping_cart, 'الواردات', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen()));
                      }),
                      _buildDrawerItem(Icons.price_check, 'التسعير اليومي', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyPricingScreen()));
                      }),
                    ],
                    iconColor: Colors.purple,
                  ),

                  // المصروفات المالية
                  _buildExpansionTile(
                    Icons.account_balance_wallet, 
                    'المصروفات المالية', 
                    [
                      _buildDrawerItem(Icons.money_off, 'المصروفات التشغيلية', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                      }),
                      _buildDrawerItem(Icons.badge, 'الرواتب والأجور', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryListScreen()));
                      }),
                    ],
                    iconColor: Colors.red.shade700,
                  ),

                  // التقارير والمالية
                  _buildExpansionTile(
                    Icons.analytics, 
                    'التقارير والمالية', 
                    [
                      _buildDrawerItem(Icons.bar_chart, 'التقارير التحليلية', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      }),
                      _buildDrawerItem(Icons.account_balance, 'سجل الديون الموحد', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CentralDebtRegisterScreen()));
                      }),
                      _buildDrawerItem(Icons.event_repeat, 'الجرد السنوي', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnualInventoriesScreen()));
                      }),
                      _buildDrawerItem(Icons.handshake, 'أرباح الشركاء', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnershipScreen()));
                      }),
                    ],
                    iconColor: Colors.teal,
                  ),

                  // الإدارة والنظام
                  _buildExpansionTile(
                    Icons.settings, 
                    'الإدارة والنظام', 
                    [
                      _buildDrawerItem(Icons.calculate, 'تجهيز الخام', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RawMeatProcessingScreen()));
                      }),
                      _buildDrawerItem(Icons.cut, 'تحويل المخزون', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StockConversionScreen()));
                      }),
                      _buildDrawerItem(Icons.settings_applications, 'الإعدادات', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      }),
                    ],
                    iconColor: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.red.shade50,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'تسجيل الخروج',
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
              'نظرة عامة (اليوم)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: metricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('خطأ: ${snapshot.error}'); // Simple error handling
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('إجمالي المبيعات', '${data.todaySales.toStringAsFixed(2)} ₪', Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard('إجمالي التحصيل', '${data.todayReceipts.toStringAsFixed(2)} ₪', Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('الذمم المستحقة', '${data.totalOutstanding.toStringAsFixed(2)} ₪', Colors.orange)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard('المصروفات', '${data.todayExpenses.toStringAsFixed(2)} ₪', Colors.red)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'آخر الفواتير',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const Text('لا توجد فواتير حديثة');
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
                      title: Text('فاتورة رقم #${invoice.id}'), // Or use invoiceNumber if available
                      subtitle: Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
                      trailing: Text(
                        '${invoice.total.toStringAsFixed(2)} ₪',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('خطأ: $err'),
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
        label: const Text('فاتورة جديدة'),
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

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
