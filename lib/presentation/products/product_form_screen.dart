import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/domain/entities/product.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late UnitType _unitType;
  late bool _isWeighted;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.defaultPrice.toString() ?? '0.0');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _unitType = widget.product?.unitType ?? UnitType.kilogram;
    _isWeighted = widget.product?.isWeighted ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      unitType: _unitType,
      isWeighted: _isWeighted,
      defaultPrice: double.tryParse(_priceController.text) ?? 0.0,
      description: _descController.text,
    );

    try {
      if (widget.product == null) {
        await ref.read(productRepositoryProvider).createProduct(product);
      } else {
        await ref.read(productRepositoryProvider).updateProduct(product);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الصنف بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'إضافة صنف جديد' : 'تعديل بيانات الصنف'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم الصنف *', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.isEmpty) ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UnitType>(
                initialValue: _unitType,
                decoration: const InputDecoration(labelText: 'وحدة القياس', border: OutlineInputBorder()),
                items: UnitType.values.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u.nameAr));
                }).toList(),
                onChanged: (val) => setState(() => _unitType = val!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('صنف موزون (يتطلب ميزان)'),
                value: _isWeighted,
                onChanged: (val) => setState(() => _isWeighted = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'السعر الافتراضي (₪)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'الوصف أو ملاحظات', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('حفظ', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
