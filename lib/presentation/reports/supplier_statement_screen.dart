import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';

enum SupplierFilter { all, paid, unpaid }

class SupplierStatementScreen extends ConsumerStatefulWidget {
  const SupplierStatementScreen({
    super.key,
    this.supplier,
  });

  final Supplier? supplier;

  @override
  ConsumerState<SupplierStatementScreen> createState() => _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends ConsumerState<SupplierStatementScreen> {
  Supplier? _selectedSupplier;
  DateTime? _fromDate;
  DateTime? _toDate;
  SupplierFilter _filter = SupplierFilter.all;
  bool _isLoading = false;
  List<SupplierStatementEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.supplier;
    if (_selectedSupplier != null) {
      _fetchStatement();
    }
  }

  Future<void> _fetchStatement() async {
    if (_selectedSupplier == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entries = await ref.read(reportRepositoryProvider).getSupplierStatement(
            _selectedSupplier!.id!,
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

  List<SupplierStatementEntry> get _filteredEntries {
    if (_filter == SupplierFilter.all) {
      return _entries;
    }
    return _entries.where((e) {
      if (e.type != 'purchase') {
        return true; // Keep payments and opening balances in view
      }
      // Actually, if filtering paid/unpaid, user probably wants to see specific invoices.
      // But a statement should be continuous. 
      // User said: "المشتريات المدفوعة" and "المشتريات غير المدفوعة"
      if (_filter == SupplierFilter.paid) {
        return e.isPaid;
      }
      if (_filter == SupplierFilter.unpaid) {
        return !e.isPaid;
      }
      return true;
    }).toList();
  }

  double get _totalPurchases => _entries.fold(0, (sum, e) => sum + e.credit);
  double get _totalPaid => _entries.fold(0, (sum, e) => sum + e.debit);
  double get _remainingBalance => _entries.isEmpty ? 0 : _entries.last.balance;

  Future<void> _exportToPdf() async {
    if (_selectedSupplier == null || _entries.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name');
      final companyPhone = prefs.getString('company_phone');
      final companyAddress = prefs.getString('company_address');

      final pdfData = await ref.read(pdfServiceProvider).generateSupplierStatementPdf(
            supplierName: _selectedSupplier!.name,
            entries: _entries,
            totalPurchases: _totalPurchases,
            totalPaid: _totalPaid,
            remainingBalance: _remainingBalance,
            fromDate: _fromDate,
            toDate: _toDate,
            companyName: companyName,
            companyPhone: companyPhone,
            companyAddress: companyAddress,
          );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'supplier_statement_${_selectedSupplier!.name}.pdf',
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
        title: const Text('كشف حساب مورد'),
        backgroundColor: Colors.orange.shade800,
        actions: [
          if (_entries.isNotEmpty && _selectedSupplier != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'تصدير PDF',
              onPressed: _exportToPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSummaryCards(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : _buildStatementList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildSmallSummaryCard('إجمالي المشتريات', _totalPurchases, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildSmallSummaryCard('إجمالي المدفوع', _totalPaid, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildSmallSummaryCard('الرصيد المتبقي', _remainingBalance, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ref.watch(suppliersStreamProvider).when(
                data: (suppliers) => DropdownButtonFormField<Supplier>(
                  initialValue: _selectedSupplier,
                  decoration: const InputDecoration(
                    labelText: 'المورد',
                    border: OutlineInputBorder(),
                  ),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ),
                        )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSupplier = val);
                    unawaited(_fetchStatement());
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل الموردين'),
              ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChip('الكل', SupplierFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('المدفوع فقط', SupplierFilter.paid),
              const SizedBox(width: 8),
              _buildFilterChip('غير المدفوع', SupplierFilter.unpaid),
            ],
          ),
          const SizedBox(height: 12),
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
                      await _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 16),
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
                      await _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _toDate == null
                        ? 'إلى تاريخ'
                        : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SupplierFilter filter) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatementList() {
    final entries = _filteredEntries;
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isOpening = entry.type == 'opening';
        
        return Container(
          color: isOpening ? Colors.grey.shade100 : Colors.white,
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.description,
                    style: TextStyle(
                      fontWeight: isOpening ? FontWeight.bold : FontWeight.normal,
                      decoration: (entry.type == 'purchase' && entry.isPaid && _filter == SupplierFilter.all) 
                          ? TextDecoration.none 
                          : TextDecoration.none,
                    ),
                  ),
                ),
                if (entry.type == 'purchase')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.isPaid ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.isPaid ? 'مدفوعة' : 'غير مدفوعة',
                      style: TextStyle(
                        fontSize: 10,
                        color: entry.isPaid ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                Row(
                  children: [
                    if (entry.credit > 0)
                      Text(
                        'علينا: ${entry.credit.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    if (entry.credit > 0 && entry.debit > 0) const SizedBox(width: 8),
                    if (entry.debit > 0)
                      Text(
                        'دفعنا: ${entry.debit.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.green, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${entry.balance.toStringAsFixed(1)} ₪',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
