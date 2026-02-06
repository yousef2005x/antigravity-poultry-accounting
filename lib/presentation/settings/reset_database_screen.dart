import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/presentation/auth/login_screen.dart';

class ResetDatabaseScreen extends ConsumerStatefulWidget {
  const ResetDatabaseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResetDatabaseScreen> createState() => _ResetDatabaseScreenState();
}

class _ResetDatabaseScreenState extends ConsumerState<ResetDatabaseScreen> {
  bool _isLoading = false;
  final _confirmController = TextEditingController();

  Future<void> _performReset() async {
    if (_confirmController.text != 'حذف') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة التأكيد غير صحيحة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(databaseProvider).clearAllData();
      
      if (mounted) {
        // Logout and go to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصفير قاعدة البيانات بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصفير قاعدة البيانات'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'تحذير هام!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                'هذا الإجراء سيقوم بحذف جميع البيانات من النظام بشكل نهائي ولن تتمكن من استرجاعها.\n\nسيتم الاحتفاظ فقط بالمستخدم الرئيسي (المدير) والمنتجات الأساسية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'اكتب كلمة "حذف" للتأكيد',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تصفير البيانات (Factory Reset)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
