import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';

class CustomerStatementScreen extends ConsumerStatefulWidget {
  const CustomerStatementScreen({
    super.key,
    this.customer,
  });

  final Customer? customer;

  @override
  ConsumerState<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends ConsumerState<CustomerStatementScreen> {
  Customer? _selectedCustomer;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  List<CustomerStatementEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    if (_selectedCustomer != null) {
      unawaited(_fetchStatement());
    }
  }

  Future<void> _fetchStatement() async {
    if (_selectedCustomer == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entries = await ref.read(reportRepositoryProvider).getCustomerStatement(
        _selectedCustomer!.id!,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب كشف الحساب: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf() async {
    if (_selectedCustomer == null || _entries.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');
      final companyAddress = prefs.getString('company_address');

      final pdfData = await ref.read(pdfServiceProvider).generateStatementPdf(
            customer: _selectedCustomer!,
            entries: _entries,
            fromDate: _fromDate,
            toDate: _toDate,
            companyName: companyName,
            companyPhone: companyPhone,
            companyAddress: companyAddress,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'statement_${_selectedCustomer!.name}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تصدير PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف حساب عميل'),
        backgroundColor: Colors.green,
        actions: [
          if (_entries.isNotEmpty && _selectedCustomer != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportToPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : _buildStatementList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ref.watch(customersStreamProvider).when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  initialValue: _selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'العميل',
                    border: OutlineInputBorder(),
                  ),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ),
                        )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedCustomer = val);
                    unawaited(_fetchStatement());
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل العملاء'),
              ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _fromDate = date);
                      unawaited(_fetchStatement());
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _fromDate == null
                        ? 'من تاريخ'
                        : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _toDate = date);
                      unawaited(_fetchStatement());
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _toDate == null
                        ? 'إلى تاريخ'
                        : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                  ),
                ),
              ),
            ],
          ),
          // Bug 2.1 Fix: Allow clearing dates for "All Time" report
          if (_fromDate != null || _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _fromDate = null;
                    _toDate = null;
                  });
                  unawaited(_fetchStatement());
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('عرض كل الفترات'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatementList() {
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isOpening = entry.description == 'رصيد سابق';

        return Container(
          color: isOpening ? Colors.grey.shade100 : Colors.white,
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.description, style: TextStyle(fontWeight: isOpening ? FontWeight.bold : FontWeight.normal)),
                Text(entry.reference, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                Row(
                  children: [
                    if (entry.debit > 0)
                      Text(
                        'دين: ${entry.debit.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    if (entry.debit > 0 && entry.credit > 0) const SizedBox(width: 8),
                    if (entry.credit > 0)
                      Text(
                        'دفع: ${entry.credit.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${entry.balance.toStringAsFixed(2)} ₪',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
