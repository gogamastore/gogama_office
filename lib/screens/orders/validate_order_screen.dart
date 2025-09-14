import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../models/order_product.dart'; // PERBAIKAN: Impor yang benar
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import 'validated_order_summary_screen.dart';

class ValidateOrderScreen extends ConsumerStatefulWidget {
  final Order order;
  const ValidateOrderScreen({super.key, required this.order});

  @override
  ConsumerState<ValidateOrderScreen> createState() => _ValidateOrderScreenState();
}

// PERBAIKAN: Gunakan OrderProduct agar konsisten dengan model Order
class _ValidatedItem {
  final OrderProduct orderProduct;
  final Product? product;
  const _ValidatedItem({required this.orderProduct, this.product});
}

class _ValidateOrderScreenState extends ConsumerState<ValidateOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Validasi Pesanan #${widget.order.id}')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat data produk: $err')),
        // PERBAIKAN: Menggunakan parameter `data` yang benar
        data: (products) {
          final productsMap = {for (var p in products) p.id: p};
          // PERBAIKAN: Menggunakan OrderProduct secara konsisten
          final validatedItems = widget.order.products.map((op) {
            final product = productsMap[op.productId];
            return _ValidatedItem(orderProduct: op, product: product);
          }).toList();

          final fullyValidatedItems = validatedItems.where((item) {
            final product = item.product;
            return product != null && product.stock >= item.orderProduct.quantity && product.price == item.orderProduct.price;
          }).toList();

          final remainingItems = validatedItems.where((item) => !fullyValidatedItems.contains(item)).toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (fullyValidatedItems.isNotEmpty)
                      _buildSection('Item Tervalidasi', fullyValidatedItems),
                    if (remainingItems.isNotEmpty)
                      _buildSection('Item Bermasalah', remainingItems),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      // Sekarang `validatedItems` akan menjadi List<OrderProduct>
                      final validatedOrderProducts = fullyValidatedItems.map((e) => e.orderProduct).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ValidatedOrderSummaryScreen(
                            originalOrder: widget.order,
                            // Kirim List<OrderProduct>
                            validatedItems: validatedOrderProducts,
                          ),
                        ),
                      );
                    },
                    child: const Text('Lanjut ke Ringkasan'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<_ValidatedItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...items.map((item) => _buildValidatedItemTile(item)),
      ],
    );
  }

  Widget _buildValidatedItemTile(_ValidatedItem item) {
    // PERBAIKAN: Gunakan `orderProduct`
    final orderProduct = item.orderProduct;
    final product = item.product;
    final isProductFound = product != null;
    final isStockSufficient = isProductFound && product.stock >= orderProduct.quantity;
    final isPriceSame = isProductFound && product.price == orderProduct.price;
    final isValid = isProductFound && isStockSufficient && isPriceSame;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isValid ? Colors.green.shade50 : Colors.orange.shade50,
      child: ListTile(
        title: Text(orderProduct.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dipesan: ${orderProduct.quantity} item'),
            if (!isProductFound)
              const Text('Status: Produk tidak ditemukan di database', style: TextStyle(color: Colors.red)),
            if (isProductFound && !isStockSufficient)
              Text('Status: Stok tidak cukup (sisa ${product.stock})', style: const TextStyle(color: Colors.red)),
            if (isProductFound && !isPriceSame)
              Text('Status: Harga berbeda (sekarang Rp ${product.price})', style: const TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: Icon(
          isValid ? Icons.check_circle : Icons.warning,
          color: isValid ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
