import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sales_invoice_form_screen.dart';

class SalesInvoiceListScreen extends ConsumerWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل فواتير المبيعات'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ref.watch(invoicesStreamProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
            data: (invoices) {
              if (invoices.isEmpty) {
                return const Center(child: Text('لا توجد فواتير مبيعات مسجلة'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final isConfirmed = invoice.status == InvoiceStatus.confirmed;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isConfirmed ? Colors.blue.shade50 : Colors.orange.shade50,
                      child: Icon(
                        Icons.description,
                        color: isConfirmed ? Colors.blue : Colors.orange,
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
                            icon: const Icon(Icons.print, color: Colors.indigo),
                            onPressed: () => _printInvoice(context, ref, invoice),
                          ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${invoice.total.toStringAsFixed(2)} ₪',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueAccent,
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
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesInvoiceFormScreen()),
        ),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context, WidgetRef ref, Invoice invoice) async {
    try {
      // Show loading (optional, but good UX)
      // Since this is stateless, we can't easily show a progress dialog without boilerplate, 
      // but Printing package handles generation async usually.
      
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');
      final companyAddress = prefs.getString('company_address');

      // We need the customer name. If invoice.customer is null (unlikely for confirmed), fetch it or use cached name.
      // But invoice.customer should be populated if we are fetching with join.
      // Assuming invoice.customer is available.
      // If items are lazy loaded, we might need to fetch them. 
      // Current `watchAllInvoices` implementation in repo usually fetches items too or we need to verify.
      // Wait, `watchAllInvoices` typically fetches the Invoice object. 
      // Does it fetch items? 
      // If `InvoiceRepositoryImpl` does `get` on `invoices` table, it DOES NOT fetch items automatically unless we use a join or separate fetch.
      // I need to check `InvoiceRepositoryImpl.watchAllInvoices`.
      
      // SAFEGUARD: Fetch full invoice with items to be sure.
      final fullInvoice = await ref.read(invoiceRepositoryProvider).getInvoiceById(invoice.id!);
      
      if (fullInvoice == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: الفاتورة غير موجودة')));
        }
        return;
      }

      final pdfData = await ref.read(pdfServiceProvider).generateInvoicePdf(
        invoice: fullInvoice,
        customer: fullInvoice.customer!, // Confirmed invoice must have customer
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
