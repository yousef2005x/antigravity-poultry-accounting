import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/backend/domain/entities/product.dart';

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
          const SnackBar(content: Text('طھظ… ط­ظپط¸ ط¨ظٹط§ظ†ط§طھ ط§ظ„طµظ†ظپ ط¨ظ†ط¬ط§ط­')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط­ظپط¸: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'ط¥ط¶ط§ظپط© طµظ†ظپ ط¬ط¯ظٹط¯' : 'طھط¹ط¯ظٹظ„ ط¨ظٹط§ظ†ط§طھ ط§ظ„طµظ†ظپ'),
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
                decoration: const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„طµظ†ظپ *', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.isEmpty) ? 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط§ظ„ط§ط³ظ…' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UnitType>(
                initialValue: _unitType,
                decoration: const InputDecoration(labelText: 'ظˆط­ط¯ط© ط§ظ„ظ‚ظٹط§ط³', border: OutlineInputBorder()),
                items: UnitType.values.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u.nameAr));
                }).toList(),
                onChanged: (val) => setState(() => _unitType = val!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('طµظ†ظپ ظ…ظˆط²ظˆظ† (ظٹطھط·ظ„ط¨ ظ…ظٹط²ط§ظ†)'),
                value: _isWeighted,
                onChanged: (val) => setState(() => _isWeighted = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ط³ط¹ط± ط§ظ„ط§ظپطھط±ط§ط¶ظٹ (â‚ھ)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                    return 'ظٹط±ط¬ظ‰ ط¥ط¯ط®ط§ظ„ ط±ظ‚ظ… طµط­ظٹط­';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ظˆطµظپ ط£ظˆ ظ…ظ„ط§ط­ط¸ط§طھ', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('ط­ظپط¸', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
