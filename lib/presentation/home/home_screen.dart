import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام محاسبة الدواجن - لوحة التحكم'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'نظام الدواجن',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'لوحة التحكم', () {}),
            _buildDrawerItem(Icons.people, 'العملاء', () {}),
            _buildDrawerItem(Icons.inventory, 'المخزون', () {}),
            _buildDrawerItem(Icons.description, 'الفواتير', () {}),
            _buildDrawerItem(Icons.payments, 'المدفوعات', () {}),
            const Divider(),
            _buildDrawerItem(Icons.settings, 'الإعدادات', () {}),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نظرة عامة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('إجمالي المبيعات', '5,230 د.أ', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('إجمالي التحصيل', '3,450 د.أ', Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('الذمم المستحقة', '1,780 د.أ', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('المصروفات', '450 د.أ', Colors.red)),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'آخر العمليات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildRecentActivityList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.receipt, color: Colors.white),
          ),
          title: Text('فاتورة مبيعات - رقم ${1000 + index}'),
          subtitle: Text('العميل: مزرعة الأمل - التاريخ: 17/01/2026'),
          trailing: const Text(
            '450 د.أ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
