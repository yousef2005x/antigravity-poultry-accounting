import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController(); // useful for footer
  final _companyAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _companyPhoneController.text = prefs.getString('company_phone') ?? '';
      _companyAddressController.text = prefs.getString('company_address') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyNameController.text);
    await prefs.setString('company_phone', _companyPhoneController.text);
    await prefs.setString('company_address', _companyAddressController.text);
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  Future<void> _backupDatabase() async {
    try {
      setState(() => _isLoading = true);
      
      // Let user pick a directory
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد لحفظ النسخة الاحتياطية',
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      final backupPath = await ref.read(backupRepositoryProvider).createBackup(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح:\n$backupPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreDatabase() async {
    // Show warning dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير هام!'),
        content: const Text(
          'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية.\n'
          'هذه العملية لا يمكن التراجع عنها.\n'
          'هل أنت متأكد من المتابعة؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، استعد البيانات'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final path = result.files.single.path!;
      await ref.read(backupRepositoryProvider).restoreBackup(path);

      if (mounted) {
        // Show success AND FORCE RESTART OR EXIT
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('تمت الاستعادة بنجاح'),
            content: const Text(
              'تم استعادة قاعدة البيانات بنجاح.\n'
              'يجب إعادة تشغيل البرنامج الآن لتطبيق التغييرات.'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => exit(0), // Force exit app
                child: const Text('إغلاق البرنامج'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل استعادة النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والنسخ الاحتياطي'),
        backgroundColor: Colors.indigo, // Different color to distinguish
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('معلومات المنشأة'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الشركة / المنشأة',
                          hintText: 'سيظهر في ترويسة الفواتير',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _companyPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          hintText: 'سيظهر في الفاتورة',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _companyAddressController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ الإعدادات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('إدارة قاعدة البيانات'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cloud_upload, color: Colors.blue, size: 32),
                        title: const Text('إنشاء نسخة احتياطية'),
                        subtitle: const Text('حفظ نسخة من قاعدة البيانات في ملف خارجي'),
                        onTap: _backupDatabase,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.cloud_download, color: Colors.red, size: 32),
                        title: const Text('استعادة نسخة احتياطية'),
                        subtitle: const Text('استبدال البيانات الحالية بنسخة سابقة (تحذير: سيتم حذف البيانات الحالية)'),
                        onTap: _restoreDatabase,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.indigo,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
