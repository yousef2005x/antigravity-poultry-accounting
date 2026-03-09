import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/payment.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({
    super.key,
    this.payment,
    this.initialType,
  });

  final Payment? payment; // For editing (optional)
  final String? initialType; // 'receipt' or 'payment'

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _type = 'receipt'; // 'receipt' (قبض) or 'payment' (صرف)
  int? _selectedCustomerId;
  int? _selectedSupplierId;
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  
  double? _partyBalance;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _type = widget.payment!.type;
      _amountController.text = widget.payment!.amount.toString();
      _selectedCustomerId = widget.payment!.customerId;
      _selectedSupplierId = widget.payment!.supplierId;
      _method = widget.payment!.method;
      _paymentDate = widget.payment!.paymentDate;
      _referenceController.text = widget.payment!.referenceNumber ?? '';
      _notesController.text = widget.payment!.notes ?? '';
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    
    // Fetch initial balance if party is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPartyBalance();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchPartyBalance() async {
    if (_type == 'receipt' && _selectedCustomerId != null) {
      setState(() => _isLoadingBalance = true);
      try {
        final balance = await ref.read(customerRepositoryProvider).getCustomerBalance(_selectedCustomerId!);
        setState(() => _partyBalance = balance);
      } finally {
        setState(() => _isLoadingBalance = false);
      }
    } else if (_type == 'payment' && _selectedSupplierId != null) {
      setState(() => _isLoadingBalance = true);
      try {
        final balance = await ref.read(supplierRepositoryProvider).getSupplierBalance(_selectedSupplierId!);
        setState(() => _partyBalance = balance);
      } finally {
        setState(() => _isLoadingBalance = false);
      }
    } else {
      setState(() => _partyBalance = null);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_type == 'receipt' && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار العميل')));
      return;
    }
    if (_type == 'payment' && _selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار المورد')));
      return;
    }

    final payment = Payment(
      id: widget.payment?.id,
      paymentNumber: widget.payment?.paymentNumber ?? '', // Repo will generate if empty
      type: _type,
      customerId: _type == 'receipt' ? _selectedCustomerId : null,
      supplierId: _type == 'payment' ? _selectedSupplierId : null,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      method: _method,
      paymentDate: _paymentDate,
      referenceNumber: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      createdBy: 1, // System default or current user ID
    );

    try {
      if (_type == 'receipt') {
        await ref.read(paymentRepositoryProvider).createReceipt(payment);
      } else {
        await ref.read(paymentRepositoryProvider).createPayment(payment);
      }
      
      if (mounted) {
        // Invalidate balance or other providers if necessary
        ref.invalidate(boxBalanceProvider);
        ref.invalidate(paymentsStreamProvider);
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدفعة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment != null ? 'تعديل دفعة' : 'تسجيل دفعة جديدة'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selection
              const Text('نوع العملية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('قبض (وارد)'),
                      value: 'receipt',
                      toggleable: true,
                      selected: _type == 'receipt',
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _type = val;
                            _selectedCustomerId = null;
                            _selectedSupplierId = null;
                            _partyBalance = null;
                          });
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('صرف (صادر)'),
                      value: 'payment',
                      toggleable: true,
                      selected: _type == 'payment',
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _type = val;
                            _selectedCustomerId = null;
                            _selectedSupplierId = null;
                            _partyBalance = null;
                          });
                        }
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Party Selection (Customer or Supplier)
              if (_type == 'receipt') ...[
                const Text('العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                customersAsync.when(
                  data: (customers) => DropdownButtonFormField<int>(
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'اختر العميل',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: customers.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCustomerId = val);
                      unawaited(_fetchPartyBalance());
                    },
                    validator: (val) => val == null ? 'يرجى اختيار العميل' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('خطأ في تحميل العملاء: $err'),
                ),
              ] else ...[
                const Text('المورد:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                suppliersAsync.when(
                  data: (suppliers) => DropdownButtonFormField<int>(
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'اختر المورد',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: suppliers.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ),).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSupplierId = val);
                      unawaited(_fetchPartyBalance());
                    },
                    validator: (val) => val == null ? 'يرجى اختيار المورد' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('خطأ في تحميل الموردين: $err'),
                ),
              ],

              // Balance Display
              if (_selectedCustomerId != null || _selectedSupplierId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الرصيد الحالي:', style: TextStyle(color: Colors.blueGrey)),
                        if (_isLoadingBalance)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Text(
                            '${_partyBalance?.toStringAsFixed(2) ?? "0.00"} ₪',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (₪) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'يرجى إدخال المبلغ';
                  }
                  if (double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'يرجى إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: PaymentMethod.values
                    .where((e) => e != PaymentMethod.credit)
                    .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.nameAr),
                ),).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _method = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Reference (for Check/Bank)
              if (_method == PaymentMethod.check || _method == PaymentMethod.bankTransfer)
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: _method == PaymentMethod.check ? 'رقم الشيك' : 'رقم الحوالة / المرجع',
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (_method == PaymentMethod.check || _method == PaymentMethod.bankTransfer)
                const SizedBox(height: 16),

              // Date Picker
              const Text('التاريخ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
                      const Icon(Icons.calendar_today, color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingBalance ? null : _save,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('حفظ الدفعة', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
