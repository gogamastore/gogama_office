import 'package:flutter/material.dart';
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
    // Hitung total langsung dari cartItems
    final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    void showEditDialog(PurchaseCartItem item) {
      final quantityController = TextEditingController(text: item.quantity.toString());
      final priceController = TextEditingController(text: item.purchasePrice.toString());

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Ubah ${item.product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Harga Beli'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newQuantity = int.tryParse(quantityController.text) ?? item.quantity;
                  final newPrice = double.tryParse(priceController.text) ?? item.purchasePrice;
                  // Gunakan metode yang benar
                  ref.read(purchaseCartProvider.notifier).updateQuantity(item.product.id, newQuantity);
                  ref.read(purchaseCartProvider.notifier).updatePrice(item.product.id, newPrice);
                  Navigator.of(context).pop();
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Pembelian'),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Keranjang Anda masih kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.quantity} x ${currencyFormatter.format(item.purchasePrice)}'),
                    trailing: Text(currencyFormatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => showEditDialog(item),
                  ),
                );
              },
            ),
      bottomNavigationBar: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormatter.format(totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: cartItems.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ProcessPurchaseScreen()),
                          );
                        },
                  child: const Text('Lanjutkan ke Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
