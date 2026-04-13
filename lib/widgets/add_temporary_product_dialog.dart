import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/providers/pos_cart_provider.dart';

class AddTemporaryProductDialog extends ConsumerStatefulWidget {
  const AddTemporaryProductDialog({super.key});

  @override
  ConsumerState<AddTemporaryProductDialog> createState() =>
      _AddTemporaryProductDialogState();
}

class _AddTemporaryProductDialogState
    extends ConsumerState<AddTemporaryProductDialog> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _productPrice = 0.0;
  int _productQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Produk Non-Katalog'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Produk'),
              onSaved: (value) => _productName = value!,
              validator: (value) =>
                  value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Harga Satuan'),
              keyboardType: TextInputType.number,
              onSaved: (value) => _productPrice = double.parse(value!),
              validator: (value) =>
                  value!.isEmpty ? 'Harga tidak boleh kosong' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Jumlah'),
              keyboardType: TextInputType.number,
              initialValue: '1',
              onSaved: (value) => _productQuantity = int.parse(value!),
              validator: (value) =>
                  value!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final temporaryProduct = Product(
                id: DateTime.now().toString(), // Unique ID for temporary product
                name: _productName,
                price: _productPrice,
                stock: _productQuantity, // Set stock to the quantity being added
                // Default values for other fields
                categoryId: 'temporary',
                image: null,
                sku: null,
                description: null,
                purchasePrice: 0,
              );
              ref.read(posCartProvider.notifier).addItem(
                    temporaryProduct,
                    _productQuantity,
                    null, // No promotions for temporary products
                  );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
