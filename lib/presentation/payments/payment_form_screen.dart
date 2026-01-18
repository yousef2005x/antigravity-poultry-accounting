import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/cash_transaction.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'in'; // 'in' for Income, 'out' for Expense

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tx = CashTransaction(
      amount: double.tryParse(_amountController.text) ?? 0.0,
      type: _type,
      description: _descController.text,
      transactionDate: DateTime.now(),
      createdBy: 1, // Default user
    );

    try {
      await ref.read(cashRepositoryProvider).createTransaction(tx);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل العملية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دفعة جديدة'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوع العملية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('قبض (وارد)'),
                      value: 'in',
                      // ignore: deprecated_member_use
                      groupValue: _type,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _type = val);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('صرف (صادر)'),
                      value: 'out',
                      // ignore: deprecated_member_use
                      groupValue: _type,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _type = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'المبلغ (₪) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال المبلغ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'الوصف / ملاحظات *', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال الوصف' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('حفظ', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
