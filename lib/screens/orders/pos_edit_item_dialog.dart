import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';

// Fungsi helper untuk parsing harga dengan aman
double parsePrice(dynamic price) {
  if (price is num) {
    return price.toDouble();
  } else if (price is String) {
    return double.tryParse(price) ?? 0.0;
  }
  return 0.0;
}

class PosEditItemDialog extends ConsumerStatefulWidget {
  final OrderItem product;

  const PosEditItemDialog({super.key, required this.product});

  @override
  ConsumerState<PosEditItemDialog> createState() => _PosEditItemDialogState();
}

class _PosEditItemDialogState extends ConsumerState<PosEditItemDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  Future<Map<String, dynamic>?>? _productDataFuture;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
    _quantityController = TextEditingController(text: _quantity.toString());
    _priceController =
        TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _productDataFuture = _fetchProductData(widget.product.productId);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchProductData(String productId) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (!productDoc.exists) throw Exception('Produk tidak ditemukan.');

      final product = Product.fromFirestore(productDoc);
      double costPrice = product.purchasePrice ?? 0.0;

      final historyQuery = await FirebaseFirestore.instance
          .collection('purchase_history')
          .where('productId', isEqualTo: productId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (historyQuery.docs.isNotEmpty) {
        costPrice = parsePrice(historyQuery.docs.first.data()['price']);
      }

      bool isPromo = false;
      final promoQuery = await FirebaseFirestore.instance
          .collection('promotions')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (promoQuery.docs.isNotEmpty) {
        isPromo = true;
      }

      return {'product': product, 'costPrice': costPrice, 'isPromo': isPromo};
    } catch (e) {
      debugPrint('Gagal mengambil data produk lengkap: $e');
      return null;
    }
  }

  void _process(double costPrice) async {
    final newPrice = double.tryParse(_priceController.text) ?? 0.0;
    final newQuantity = _quantity; // --- FIX: Use state quantity

    if (newQuantity <= 0) {
      // Opsi untuk menghapus item jika kuantitas 0
      final bool? confirmRemove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Item?'),
          content: const Text('Kuantitas adalah 0. Apakah Anda ingin menghapus item ini dari keranjang?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
          ],
        ),
      );
      if (confirmRemove == true) {
         Navigator.of(context).pop(widget.product.copyWith(quantity: 0));
      }
      return;
    }

    if (newPrice < costPrice) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Peringatan Harga Jual'),
          content: Text(
              'Harga jual (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(newPrice)}) di bawah harga modal (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(costPrice)}). Apakah Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Tidak')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Ya, Yakin')),
          ],
        ),
      );
      if (proceed != true) {
        return;
      }
    }

    Navigator.of(context).pop(
      widget.product.copyWith(price: newPrice, quantity: newQuantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _productDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
              content: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Gagal memuat detail harga produk. Silakan coba lagi.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'))
            ],
          );
        }

        final productData = snapshot.data!;
        final costPrice = productData['costPrice'] as double;
        final isPromo = productData['isPromo'] as bool;

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(widget.product.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              if (isPromo)
                const Chip(
                  label: Text('PROMO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SKU: ${widget.product.sku}'),
                const SizedBox(height: 8),
                Text('Harga Modal: ${currencyFormatter.format(costPrice)} ',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                // --- FIX: ADD QUANTITY BUTTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (_quantity > 0) {
                          setState(() {
                            _quantity--;
                            _quantityController.text = _quantity.toString();
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _quantityController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder()),
                        onChanged: (value) {
                          final newQuantity = int.tryParse(value);
                          if (newQuantity != null && newQuantity >= 0) {
                            _quantity = newQuantity;
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                          _quantityController.text = _quantity.toString();
                        });
                      },
                    ),
                  ],
                ),
                // --- END FIX ---
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga Jual Satuan',
                    prefixText: 'Rp ',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => _process(costPrice),
              child: const Text('Proses'),
            ),
          ],
        );
      },
    );
  }
}
