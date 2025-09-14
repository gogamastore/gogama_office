import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart'; // Impor yang benar

class AddProductToOrderDialog extends ConsumerStatefulWidget {
  const AddProductToOrderDialog({super.key});

  @override
  AddProductToOrderDialogState createState() => AddProductToOrderDialogState();
}

class AddProductToOrderDialogState extends ConsumerState<AddProductToOrderDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Menggunakan nama provider yang benar `allProductsProvider`
    final productsAsyncValue = ref.watch(allProductsProvider);

    return AlertDialog(
      title: const Text('Tambah Produk ke Pesanan'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            productsAsyncValue.when(
              data: (products) {
                return DropdownButtonFormField<Product>(
                  hint: const Text('Pilih Produk'),
                  initialValue: _selectedProduct,
                  isExpanded: true,
                  items: products.map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (Product? newValue) {
                    setState(() {
                      _selectedProduct = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Produk harus dipilih' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Gagal memuat produk: $err'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            if (_selectedProduct != null && _quantityController.text.isNotEmpty) {
              final quantity = int.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                // Kembalikan produk dan kuantitas yang dipilih
                Navigator.of(context).pop({
                  'product': _selectedProduct,
                  'quantity': quantity,
                });
              }
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
