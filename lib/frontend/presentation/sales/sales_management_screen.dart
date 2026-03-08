import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/backend/domain/entities/invoice.dart';
import 'package:poultry_accounting/backend/domain/entities/payment.dart';
import 'package:poultry_accounting/frontend/presentation/payments/payment_form_screen.dart';
import 'package:poultry_accounting/frontend/presentation/sales/sales_invoice_form_screen.dart';
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
        title: const Text('ط§ظ„ظ…ط¨ظٹط¹ط§طھ ظˆط§ظ„طھط­طµظٹظ„'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'ط§ظ„ظپظˆط§طھظٹط±'),
            Tab(icon: Icon(Icons.payments), text: 'ط§ظ„ظ…ط¯ظپظˆط¹ط§طھ'),
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
        label: Text(_tabController.index == 0 ? 'ظپط§طھظˆط±ط© ط¬ط¯ظٹط¯ط©' : 'ط¯ظپط¹ط© ط¬ط¯ظٹط¯ط©'),
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
      error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('ظ„ط§ طھظˆط¬ط¯ ظپظˆط§طھظٹط± ظ…ط¨ظٹط¹ط§طھ ظ…ط³ط¬ظ„ط©', style: TextStyle(color: Colors.grey)),
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
                  'ظپط§طھظˆط±ط© ط±ظ‚ظ…: ${invoice.invoiceNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ط§ظ„ط¹ظ…ظٹظ„: ${invoice.customer?.name ?? (invoice.customerId == 0 ? "ظ†ظ‚ط¯ظٹ" : "طھط­ظ…ظٹظ„...")}'),
                    Text(
                      'ط§ظ„طھط§ط±ظٹط®: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
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
                        tooltip: 'ط·ط¨ط§ط¹ط©',
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${invoice.total.toStringAsFixed(2)} â‚ھ',
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
            const SnackBar(content: Text('ط®ط·ط£: ط§ظ„ظپط§طھظˆط±ط© ط؛ظٹط± ظ…ظˆط¬ظˆط¯ط©')),
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
          SnackBar(content: Text('ظپط´ظ„ ط§ظ„ط·ط¨ط§ط¹ط©: $e'), backgroundColor: Colors.red),
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
          child: ref.watch(paymentsStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('ظ„ط§ ظٹظˆط¬ط¯ ط¹ظ…ظ„ظٹط§طھ ظ…ط³ط¬ظ„ط©', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final payment = transactions[index];
                  final isReceipt = payment.type == 'receipt';
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isReceipt ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isReceipt ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        payment.customer?.name ?? payment.supplier?.name ?? 'ط¬ظ‡ط© ط؛ظٹط± ظ…ط¹ط±ظˆظپط©',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${payment.paymentNumber} - ${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.blue),
                            onPressed: () => _printReceipt(context, ref, payment),
                            tooltip: 'ط·ط¨ط§ط¹ط© ظˆط±ظٹظپظٹظˆ',
                          ),
                          Text(
                            '${payment.amount.toStringAsFixed(2)} â‚ھ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isReceipt ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentFormScreen(payment: payment),
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

  Future<void> _printReceipt(BuildContext context, WidgetRef ref, Payment payment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');
      final companyAddress = prefs.getString('company_address');

      final pdfData = await ref.read(pdfServiceProvider).generatePaymentReceiptPdf(
            payment: payment,
            companyName: companyName,
            companyPhone: companyPhone,
            companyAddress: companyAddress,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: '${payment.paymentNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط·ط¨ط§ط¹ط©: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
              'ط±طµظٹط¯ ط§ظ„طµظ†ط¯ظˆظ‚ ط§ظ„ط­ط§ظ„ظٹ',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${balance.toStringAsFixed(2)} â‚ھ',
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
