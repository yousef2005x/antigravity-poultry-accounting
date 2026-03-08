import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/partner.dart';

class PartnerFormScreen extends ConsumerStatefulWidget {
  const PartnerFormScreen({super.key, this.partner});

  final Partner? partner;

  @override
  ConsumerState<PartnerFormScreen> createState() => _PartnerFormScreenState();
}

class _PartnerFormScreenState extends ConsumerState<PartnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shareController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name ?? '');
    _shareController = TextEditingController(text: widget.partner?.sharePercentage.toString() ?? '50.0');
    _isActive = widget.partner?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    super.dispose();
  }

  Future<void> _savePartner() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(partnerRepositoryProvider);
      final partner = Partner(
        id: widget.partner?.id,
        name: _nameController.text,
        sharePercentage: double.parse(_shareController.text),
        isActive: _isActive,
      );

      try {
        if (widget.partner == null) {
          await repo.createPartner(partner);
        } else {
          await repo.updatePartner(partner);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('طھظ… ط­ظپط¸ ط¨ظٹط§ظ†ط§طھ ط§ظ„ط´ط±ظٹظƒ ط¨ظ†ط¬ط§ط­')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ط­ط¯ط« ط®ط·ط£: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partner == null ? 'ط¥ط¶ط§ظپط© ط´ط±ظٹظƒ ط¬ط¯ظٹط¯' : 'طھط¹ط¯ظٹظ„ ط¨ظٹط§ظ†ط§طھ ط§ظ„ط´ط±ظٹظƒ'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„ط´ط±ظٹظƒ', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ظ„ط§ط³ظ…' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shareController,
                decoration: const InputDecoration(labelText: 'ظ†ط³ط¨ط© ط§ظ„ط´ط±ط§ظƒط© (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ظ„ظ†ط³ط¨ط©';
                  }
                  final share = double.tryParse(value);
                  if (share == null || share < 0 || share > 100) {
                    return 'ظ†ط³ط¨ط© ط؛ظٹط± طµط­ظٹط­ط©';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('ظ†ط´ط·'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePartner,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('ط­ظپط¸', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
