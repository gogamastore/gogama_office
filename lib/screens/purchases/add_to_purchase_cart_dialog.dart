import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _quantity = 1;
  late double _purchasePrice; // Dibuat `late` karena akan diinisialisasi di initState

  @override
  void initState() {
    super.initState();
    // Inisialisasi harga beli dengan harga beli terakhir dari produk.
    // Jika null (belum pernah dibeli), fallback ke 0.0
    _purchasePrice = widget.product.lastPurchasePrice ?? 0.0;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ref.read(purchaseCartProvider.notifier).addProduct(
            widget.product,
            _purchasePrice,
            _quantity,
          );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.name} ditambahkan ke keranjang pembelian.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah ke Keranjang Pembelian'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _quantity.toString(),
              decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Masukkan jumlah yang valid.';
                }
                return null;
              },
              onSaved: (value) => _quantity = int.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              // Menggunakan `key` untuk memastikan `initialValue` diperbarui saat widget dibangun ulang
              key: Key(_purchasePrice.toString()),
              initialValue: _purchasePrice.toStringAsFixed(2), // Menampilkan 2 angka desimal
              decoration: const InputDecoration(labelText: 'Harga Beli per Unit', prefixText: 'Rp ', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || double.tryParse(value.replaceAll(',', '.')) == null || double.parse(value.replaceAll(',', '.')) < 0) {
                  return 'Masukkan harga yang valid.';
                }
                return null;
              },
              onSaved: (value) => _purchasePrice = double.parse(value!.replaceAll(',', '.')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: _submit, child: const Text('Tambah')),
      ],
    );
  }
}
