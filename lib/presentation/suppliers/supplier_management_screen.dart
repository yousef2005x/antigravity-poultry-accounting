import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/supplier.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/presentation/suppliers/supplier_form_screen.dart';

enum SupplierFilter { all, paid, unpaid }

class SupplierManagementScreen extends ConsumerStatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  ConsumerState<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends ConsumerState<SupplierManagementScreen>
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
        title: const Text('إدارة الموردين'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'قائمة الموردين'),
            Tab(icon: Icon(Icons.assessment), text: 'كشف الحساب'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SupplierListTab(),
          _SupplierStatementTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddSupplierDialog(context),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
    );
  }
}

// Tab 1: Supplier List
class _SupplierListTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(suppliersStreamProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
      data: (suppliers) {
        if (suppliers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا يوجد موردين مضافين بعد', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: suppliers.length,
          itemBuilder: (context, index) {
            final supplier = suppliers[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.business, color: Colors.orange),
                ),
                title: Text(
                  supplier.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (supplier.phone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(supplier.phone!),
                        ],
                      ),
                    if (supplier.address != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              supplier.address!,
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
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupplierFormScreen(supplier: supplier),
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

// Tab 2: Supplier Statement
class _SupplierStatementTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SupplierStatementTab> createState() => _SupplierStatementTabState();
}

class _SupplierStatementTabState extends ConsumerState<_SupplierStatementTab> {
  Supplier? _selectedSupplier;
  DateTime? _fromDate;
  DateTime? _toDate;
  SupplierFilter _filter = SupplierFilter.all;
  bool _isLoading = false;
  List<SupplierStatementEntry> _entries = [];

  Future<void> _fetchStatement() async {
    if (_selectedSupplier == null) return;

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
    if (_filter == SupplierFilter.all) return _entries;
    return _entries.where((e) {
      if (e.type != 'purchase') return true;
      if (_filter == SupplierFilter.paid) return e.isPaid;
      if (_filter == SupplierFilter.unpaid) return !e.isPaid;
      return true;
    }).toList();
  }

  double get _totalPurchases => _entries.fold(0, (sum, e) => sum + e.credit);
  double get _totalPaid => _entries.fold(0, (sum, e) => sum + e.debit);
  double get _remainingBalance => _entries.isEmpty ? 0 : _entries.last.balance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        if (_entries.isNotEmpty) _buildSummaryCards(),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredEntries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('اختر مورداً لعرض كشف الحساب', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _buildStatementList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSmallSummaryCard('إجمالي المشتريات', _totalPurchases, Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallSummaryCard('إجمالي المدفوع', _totalPaid, Colors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallSummaryCard('الرصيد المتبقي', _remainingBalance, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 4),
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
                  value: _selectedSupplier,
                  decoration: InputDecoration(
                    labelText: 'اختر المورد',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.business, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.orange.shade50,
                  ),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSupplier = val);
                    _fetchStatement();
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
                      _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 16),
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
                  icon: const Icon(Icons.date_range, size: 16),
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

  Widget _buildFilterChip(String label, SupplierFilter filter) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
