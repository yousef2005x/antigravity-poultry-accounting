import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/services/pdf_service.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/presentation/customers/customer_form_screen.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends ConsumerState<CustomerManagementScreen>
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
        title: const Text('إدارة العملاء'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'قائمة العملاء'),
            Tab(icon: Icon(Icons.assessment), text: 'كشف الحساب'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CustomerListTab(),
          _CustomerStatementTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddCustomerDialog(context),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
  }
}

// Tab 1: Customer List
class _CustomerListTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(customersStreamProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
      data: (customers) {
        if (customers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد عملاء مضافين بعد', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer.phone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(customer.phone!),
                        ],
                      ),
                    if (customer.address != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerFormScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Tab 2: Customer Statement
class _CustomerStatementTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CustomerStatementTab> createState() => _CustomerStatementTabState();
}

class _CustomerStatementTabState extends ConsumerState<_CustomerStatementTab> {
  Customer? _selectedCustomer;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  List<CustomerStatementEntry> _entries = [];

  Future<void> _fetchStatement() async {
    if (_selectedCustomer == null) return;

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
    if (_selectedCustomer == null || _entries.isEmpty) return;

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
    return Column(
      children: [
        _buildFilters(),
        if (_entries.isNotEmpty && _selectedCustomer != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _exportToPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('تصدير PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('اختر عميلاً لعرض كشف الحساب', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _buildStatementList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ref.watch(customersStreamProvider).when(
                data: (customers) => DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  decoration: InputDecoration(
                    labelText: 'اختر العميل',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedCustomer = val);
                    _fetchStatement();
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
                      _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_fromDate == null
                      ? 'من تاريخ'
                      : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'),
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
                      _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_toDate == null
                      ? 'إلى تاريخ'
                      : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'),
                ),
              ),
            ],
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
                Expanded(
                  child: Text(
                    entry.description,
                    style: TextStyle(fontWeight: isOpening ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
