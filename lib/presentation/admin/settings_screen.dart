import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/core/providers/auth_provider.dart';
import 'package:poultry_accounting/core/utils/security_utils.dart';
import 'package:poultry_accounting/core/services/sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final smsServiceProvider = Provider((ref) => SmsService());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController(); // useful for footer
  final _companyAddressController = TextEditingController();
  final _timeoutController = TextEditingController();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _userPhoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPasswordSection = false;
  bool _otpSent = false;
  bool _isPhoneVerified = false;

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
    _timeoutController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final user = ref.read(authProvider).user;
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? '';
      _companyPhoneController.text = prefs.getString('company_phone') ?? '';
      _companyAddressController.text = prefs.getString('company_address') ?? '';
      _timeoutController.text = (prefs.getInt('session_timeout_minutes') ?? 10).toString();
      _userPhoneController.text = user?.phoneNumber ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyNameController.text);
    await prefs.setString('company_phone', _companyPhoneController.text);
    await prefs.setString('company_address', _companyAddressController.text);
    await prefs.setInt('session_timeout_minutes', int.tryParse(_timeoutController.text) ?? 10);
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

  Future<void> _changePassword() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (_oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة المرور الحالية'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء التحقق من رقم الهاتف أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(userRepositoryProvider).changePassword(
        user.id!, 
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: Colors.green),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _otpController.clear();
        setState(() {
          _showPasswordSection = false;
          _otpSent = false;
          _isPhoneVerified = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تغيير كلمة المرور: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_userPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الهاتف أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(smsServiceProvider).sendVerificationCode(_userPhoneController.text);
      if (success && mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رمز التحقق إلى هاتفك'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الرمز: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز التحقق'), backgroundColor: Colors.red),
      );
      return;
    }

    final verified = ref.read(smsServiceProvider).verifyCode(
      _userPhoneController.text, 
      _otpController.text,
    );

    if (verified) {
      setState(() {
        _isPhoneVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التحقق من رقم الهاتف بنجاح'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز التحقق غير صحيح'), backgroundColor: Colors.red),
      );
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
                      TextField(
                        controller: _timeoutController,
                        decoration: const InputDecoration(
                          labelText: 'فترة الخمول قبل تسجيل الخروج (بالدقائق)',
                          hintText: 'مثلاً: 10',
                          border: OutlineInputBorder(),
                          suffixText: 'دقيقة',
                        ),
                        keyboardType: TextInputType.number,
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
              _buildSectionHeader('الأمان'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline, color: Colors.orange),
                        title: const Text('تغيير كلمة المرور'),
                        trailing: IconButton(
                          icon: Icon(_showPasswordSection ? Icons.expand_less : Icons.expand_more),
                          onPressed: () => setState(() => _showPasswordSection = !_showPasswordSection),
                        ),
                        onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
                      ),
                      if (_showPasswordSection) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        if (!_isPhoneVerified) ...[
                          const Text('لإجراء هذا التغيير، يجب التحقق من رقم هاتف صاحب العمل:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _userPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم هاتف صاحب العمل',
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: !_otpSent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                child: Text(_otpSent ? 'إعادة الإرسال' : 'إرسال الرمز'),
                              ),
                            ],
                          ),
                          if (_otpSent) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _otpController,
                                    decoration: const InputDecoration(
                                      labelText: 'رمز التحقق (SMS)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyOtp,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  child: const Text('تحقق'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('تم التحقق من رقم الهاتف بنجاح', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _oldPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور الحالية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور الجديدة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور الجديدة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                              child: const Text('تحديث كلمة المرور'),
                            ),
                          ),
                        ],
                      ],
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
