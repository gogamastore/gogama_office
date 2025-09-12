import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/purchase_cart_item.dart';
import '../../providers/purchase_provider.dart';

class EditPurchaseCartItemDialog extends ConsumerStatefulWidget {
  final PurchaseCartItem cartItem;

  const EditPurchaseCartItemDialog({super.key, required this.cartItem});

  @override
  ConsumerState<EditPurchaseCartItemDialog> createState() => _EditPurchaseCartItemDialogState();
}

class _EditPurchaseCartItemDialogState extends ConsumerState<EditPurchaseCartItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _quantity;
  late double _purchasePrice;
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.cartItem.quantity;
    _purchasePrice = widget.cartItem.purchasePrice;
    _priceController.text = _purchasePrice.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Menggunakan nama metode yang BENAR
      ref.read(purchaseCartProvider.notifier).updateQuantity(widget.cartItem.product.id, _quantity);
      ref.read(purchaseCartProvider.notifier).updatePrice(widget.cartItem.product.id, _purchasePrice);
      Navigator.of(context).pop();
    }
  }

  void _delete() {
    // Menggunakan nama metode yang BENAR
    ref.read(purchaseCartProvider.notifier).removeProduct(widget.cartItem.product.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.cartItem.product.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga Beli per Item',
                prefixText: 'Rp ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Harga tidak boleh kosong';
                if (double.tryParse(value) == null) return 'Format harga tidak valid';
                return null;
              },
              onSaved: (value) => _purchasePrice = double.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _quantity.toString(),
              decoration: const InputDecoration(labelText: 'Jumlah'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Jumlah tidak boleh kosong';
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
              onSaved: (value) => _quantity = int.parse(value!),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Ionicons.trash_outline, color: Colors.red),
          onPressed: _delete,
          tooltip: 'Hapus Item',
        ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
