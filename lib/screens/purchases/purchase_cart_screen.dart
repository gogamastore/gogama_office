
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_cart_item.dart';
import '../../providers/purchase_provider.dart';
import 'process_purchase_screen.dart';

class PurchaseCartScreen extends ConsumerWidget {
  const PurchaseCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(purchaseCartProvider);
    final totalAmount = ref.watch(purchaseTotalProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Pembelian'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Keranjang Anda masih kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tambahkan produk dari halaman pembelian.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return _buildCartItemCard(context, ref, item, currencyFormatter);
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildSummaryBottomBar(context, currencyFormatter.format(totalAmount)),
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, PurchaseCartItem item, NumberFormat currencyFormatter) {
    // Controller untuk mengelola input harga
    final priceController = TextEditingController(text: item.purchasePrice.toStringAsFixed(0));
    
    // Atur posisi kursor ke akhir teks
    priceController.selection = TextSelection.fromPosition(TextPosition(offset: priceController.text.length));


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    ref.read(purchaseCartProvider.notifier).removeItem(item.product.id);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.product.name} dihapus dari keranjang.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Baris untuk mengedit harga
            Row(
              children: [
                const Text('Harga Beli:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                       final newPrice = double.tryParse(value) ?? 0;
                       ref.read(purchaseCartProvider.notifier).updateItemPrice(item.product.id, newPrice);
                    },
                  ),
                ),
              ],
            ),
             const SizedBox(height: 12),
            // Baris untuk kuantitas dan subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Jumlah:', style: TextStyle(fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: item.quantity > 1
                          ? () => ref.read(purchaseCartProvider.notifier).updateItemQuantity(item.product.id, item.quantity - 1)
                          : null, // Disable tombol jika kuantitas 1
                    ),
                    Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => ref.read(purchaseCartProvider.notifier).updateItemQuantity(item.product.id, item.quantity + 1),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(item.subtotal),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk bar ringkasan di bagian bawah
  Widget _buildSummaryBottomBar(BuildContext context, String formattedTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pembelian', style: TextStyle(color: Colors.grey)),
              Text(
                formattedTotal,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProcessPurchaseScreen()),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Lanjutkan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
