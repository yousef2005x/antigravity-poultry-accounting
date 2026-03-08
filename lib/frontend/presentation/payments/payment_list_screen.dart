import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/backend/domain/entities/payment.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_form_screen.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ط³ط¬ظ„ ط§ظ„ظ…ط¯ظپظˆط¹ط§طھ ظˆط§ظ„ظ‚ط¨ط¶'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildBalanceSummary(ref),
          Expanded(
            child: ref.watch(paymentsStreamProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('ط®ط·ط£: $err')),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('ظ„ط§ ظٹظˆط¬ط¯ ط³ظ†ط¯ط§طھ ظ…ط³ط¬ظ„ط©', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final isReceipt = payment.type == 'receipt';
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isReceipt ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(
                            isReceipt ? Icons.add_circle : Icons.remove_circle,
                            color: isReceipt ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              payment.customer?.name ?? payment.supplier?.name ?? 'ط¬ظ‡ط© ط؛ظٹط± ظ…ط¹ط±ظˆظپط©',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${payment.amount.toStringAsFixed(2)} â‚ھ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isReceipt ? Colors.green : Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    payment.paymentNumber,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  payment.methodDisplayName,
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                            if (payment.notes != null && payment.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  payment.notes!,
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              onPressed: () => _printReceipt(context, ref, payment),
                              tooltip: 'ط·ط¨ط§ط¹ط© ظˆط±ظٹظپظٹظˆ',
                            ),
                            const Icon(Icons.chevron_left, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          // Show details or edit
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentFormScreen(payment: payment),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('ط³ظ†ط¯ ط¬ط¯ظٹط¯'),
      ),
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
      error: (err, stack) => Text('Error: $err'),
      data: (balance) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(bottom: BorderSide(color: Colors.green.shade200)),
        ),
        child: Column(
          children: [
            const Text('ط±طµظٹط¯ ط§ظ„طµظ†ط¯ظˆظ‚ ط§ظ„ط­ط§ظ„ظٹ', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '${balance.toStringAsFixed(2)} â‚ھ',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
