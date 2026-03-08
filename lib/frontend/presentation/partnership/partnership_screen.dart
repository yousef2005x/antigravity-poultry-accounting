import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/partner.dart';
import 'package:poultry_accounting/backend/domain/entities/partner_transaction.dart';
import 'package:poultry_accounting/backend/domain/repositories/report_repository.dart';
import 'package:poultry_accounting/frontend/presentation/partnership/partner_form_screen.dart';

class PartnershipScreen extends ConsumerStatefulWidget {
  const PartnershipScreen({super.key});

  @override
  ConsumerState<PartnershipScreen> createState() => _PartnershipScreenState();
}

class _PartnershipScreenState extends ConsumerState<PartnershipScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ط¥ط¯ط§ط±ط© ط§ظ„ط´ط±ظƒط§ط، ظˆط§ظ„ط£ط±ط¨ط§ط­'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfitSummaryCard(),
            const SizedBox(height: 24),
            const Text('ط§ظ„ط´ط±ظƒط§ط، ط§ظ„ظ…ط³طھظپظٹط¯ظˆظ† (ط§ظ„ظ…ظ†ط§طµظپط© 50/50)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(child: _buildPartnersList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerFormScreen()));
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfitSummaryCard() {
    final reportAsync = ref.watch(reportRepositoryProvider).getProfitLossReport();

    return FutureBuilder<ProfitLossReport>(
      future: reportAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final report = snapshot.data!;

        return Card(
          color: Colors.green.shade700,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('ط¥ط¬ظ…ط§ظ„ظٹ ط§ظ„ط±ط¨ط­ ط§ظ„طµط§ظپظٹ ط§ظ„ط¬ط§ظ‡ط² ظ„ظ„طھظˆط²ظٹط¹', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Text(
                  '${report.profit.toStringAsFixed(2)} â‚ھ',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareColumn('ط§ظ„ط¥ظٹط±ط§ط¯ط§طھ', report.revenue),
                    _buildShareColumn('ط§ظ„ظ…طµط±ظˆظپط§طھ', report.expenses + report.cost), // Total costs
                  ], 
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareColumn(String title, double amount) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(
          '${amount.toStringAsFixed(2)} â‚ھ',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPartnersList() {
    final partnersAsync = ref.watch(partnerRepositoryProvider).getAllPartners();

    return FutureBuilder<List<Partner>>(
      future: partnersAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final partner = snapshot.data![index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(partner.name),
                subtitle: Text('ط§ظ„ظ†ط³ط¨ط©: ${partner.sharePercentage}%'),
                trailing: ElevatedButton(
                  onPressed: () => _showDrawingDialog(partner),
                  child: const Text('ط³ط­ط¨ ط£ط±ط¨ط§ط­'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDrawingDialog(Partner partner) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ط³ط­ط¨ ط£ط±ط¨ط§ط­ - ${partner.name}'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'ط§ظ„ظ…ط¨ظ„ط؛ (â‚ھ)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ط¥ظ„ط؛ط§ط،')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                final repo = ref.read(partnerRepositoryProvider);
                await repo.createPartnerTransaction(PartnerTransaction(
                  partnerId: partner.id!,
                  amount: amount,
                  type: 'drawing',
                  transactionDate: DateTime.now(),
                  createdBy: 1,
                  notes: 'ط³ط­ط¨ ط£ط±ط¨ط§ط­ ظٹط¯ظˆظٹ',
                ),);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طھظ… طھط³ط¬ظٹظ„ ط¹ظ…ظ„ظٹط© ط§ظ„ط³ط­ط¨')));
                }
              }
            },
            child: const Text('طھط£ظƒظٹط¯ ط§ظ„ط³ط­ط¨'),
          ),
        ],
      ),
    );
  }
}
