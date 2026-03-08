import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/frontend/presentation/auth/login_screen.dart';

class ResetDatabaseScreen extends ConsumerStatefulWidget {
  const ResetDatabaseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResetDatabaseScreen> createState() => _ResetDatabaseScreenState();
}

class _ResetDatabaseScreenState extends ConsumerState<ResetDatabaseScreen> {
  bool _isLoading = false;
  final _confirmController = TextEditingController();

  Future<void> _performReset() async {
    if (_confirmController.text != 'ط­ط°ظپ') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ظƒظ„ظ…ط© ط§ظ„طھط£ظƒظٹط¯ ط؛ظٹط± طµط­ظٹط­ط©')),
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
          const SnackBar(content: Text('طھظ… طھطµظپظٹط± ظ‚ط§ط¹ط¯ط© ط§ظ„ط¨ظٹط§ظ†ط§طھ ط¨ظ†ط¬ط§ط­')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط­ط¯ط« ط®ط·ط£: $e')),
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
        title: const Text('طھطµظپظٹط± ظ‚ط§ط¹ط¯ط© ط§ظ„ط¨ظٹط§ظ†ط§طھ'),
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
                'طھط­ط°ظٹط± ظ‡ط§ظ…!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                'ظ‡ط°ط§ ط§ظ„ط¥ط¬ط±ط§ط، ط³ظٹظ‚ظˆظ… ط¨ط­ط°ظپ ط¬ظ…ظٹط¹ ط§ظ„ط¨ظٹط§ظ†ط§طھ ظ…ظ† ط§ظ„ظ†ط¸ط§ظ… ط¨ط´ظƒظ„ ظ†ظ‡ط§ط¦ظٹ ظˆظ„ظ† طھطھظ…ظƒظ† ظ…ظ† ط§ط³طھط±ط¬ط§ط¹ظ‡ط§.\n\nط³ظٹطھظ… ط§ظ„ط§ط­طھظپط§ط¸ ظپظ‚ط· ط¨ط§ظ„ظ…ط³طھط®ط¯ظ… ط§ظ„ط±ط¦ظٹط³ظٹ (ط§ظ„ظ…ط¯ظٹط±) ظˆط§ظ„ظ…ظ†طھط¬ط§طھ ط§ظ„ط£ط³ط§ط³ظٹط©.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'ط§ظƒطھط¨ ظƒظ„ظ…ط© "ط­ط°ظپ" ظ„ظ„طھط£ظƒظٹط¯',
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
                    : const Text('طھطµظپظٹط± ط§ظ„ط¨ظٹط§ظ†ط§طھ (Factory Reset)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
