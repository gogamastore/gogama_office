
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../providers/purchase_provider.dart';

class AddToPurchaseCartDialog extends ConsumerStatefulWidget {
  final Product product;

  const AddToPurchaseCartDialog({super.key, required this.product});

  @override
  _AddToPurchaseCartDialogState createState() => _AddToPurchaseCartDialogState();
}

class _AddToPurchaseCartDialogState extends ConsumerState<AddToPurchaseCartDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    // Menggunakan harga beli dari produk sebagai default
    _priceController = TextEditingController(
      text: currencyFormatter.format(widget.product.purchasePrice ?? 0),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final price = double.tryParse(_priceController.text.replaceAll('.', '')) ?? widget.product.purchasePrice ?? 0;

      ref.read(purchaseCartProvider.notifier).addItem(widget.product, quantity, price);
      
      Navigator.of(context).pop(); // Tutup dialog setelah berhasil

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} ditambahkan ke keranjang.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah ke Keranjang'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan jumlah dan harga beli untuk: ${widget.product.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Beli (Satuan)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
               validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harga tidak boleh kosong';
                }
                if (double.tryParse(value.replaceAll('.', '')) == null) {
                  return 'Masukkan harga yang valid';
                }
                return null;
              },
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
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
