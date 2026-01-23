import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/presentation/sales/sales_invoice_form_screen.dart';
import 'package:poultry_accounting/presentation/payments/payment_form_screen.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesManagementScreen extends ConsumerStatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  ConsumerState<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends ConsumerState<SalesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات والتحصيل'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'الفواتير'),
            Tab(icon: Icon(Icons.payments), text: 'المدفوعات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InvoicesTab(),
          _PaymentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            // New Invoice
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SalesInvoiceFormScreen()),
            );
          } else {
            // New Payment
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
            );
          }
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'فاتورة جديدة' : 'دفعة جديدة'),
      ),
    );
  }
}

// Tab 1: Invoices List
class _InvoicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(invoicesStreamProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد فواتير مبيعات مسجلة', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final isConfirmed = invoice.status == InvoiceStatus.confirmed;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isConfirmed ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Icon(
                    Icons.description,
                    color: isConfirmed ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  'فاتورة رقم: ${invoice.invoiceNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العميل: ${invoice.customer?.name ?? (invoice.customerId == 0 ? "نقدي" : "تحميل...")}'),
                    Text(
                      'التاريخ: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isConfirmed)
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.green),
                        onPressed: () => _printInvoice(context, ref, invoice),
                        tooltip: 'طباعة',
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${invoice.total.toStringAsFixed(2)} ₪',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          invoice.statusDisplayName,
                          style: TextStyle(
                            color: isConfirmed ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalesInvoiceFormScreen(invoice: invoice),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _printInvoice(BuildContext context, WidgetRef ref, Invoice invoice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');
      final companyAddress = prefs.getString('company_address');

      final fullInvoice = await ref.read(invoiceRepositoryProvider).getInvoiceById(invoice.id!);

      if (fullInvoice == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: الفاتورة غير موجودة')),
          );
        }
        return;
      }

      final pdfData = await ref.read(pdfServiceProvider).generateInvoicePdf(
            invoice: fullInvoice,
            customer: fullInvoice.customer!,
            companyName: companyName,
            companyPhone: companyPhone,
            companyAddress: companyAddress,
          );

      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'invoice_${fullInvoice.invoiceNumber}.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الطباعة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Tab 2: Payments List
class _PaymentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildBalanceSummary(ref),
        Expanded(
          child: ref.watch(transactionsStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا يوجد عمليات مسجلة', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isIn = tx.type == 'in';
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIn ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        tx.description.isEmpty ? (isIn ? 'قبض' : 'صرف') : tx.description,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${tx.transactionDate.year}-${tx.transactionDate.month}-${tx.transactionDate.day}',
                      ),
                      trailing: Text(
                        '${tx.amount} ₪',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isIn ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(WidgetRef ref) {
    return ref.watch(boxBalanceProvider).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (balance) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'رصيد الصندوق الحالي',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${balance.toStringAsFixed(2)} ₪',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
