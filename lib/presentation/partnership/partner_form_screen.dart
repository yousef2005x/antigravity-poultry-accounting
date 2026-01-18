import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/partner.dart';

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
            const SnackBar(content: Text('تم حفظ بيانات الشريك بنجاح')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partner == null ? 'إضافة شريك جديد' : 'تعديل بيانات الشريك'),
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
                decoration: const InputDecoration(labelText: 'اسم الشريك', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shareController,
                decoration: const InputDecoration(labelText: 'نسبة الشراكة (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال النسبة';
                  }
                  final share = double.tryParse(value);
                  if (share == null || share < 0 || share > 100) {
                    return 'نسبة غير صحيحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('نشط'),
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
                  child: const Text('حفظ', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
