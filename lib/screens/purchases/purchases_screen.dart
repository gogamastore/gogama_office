import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../models/purchase_cart_item.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import 'add_to_purchase_cart_dialog.dart';
import 'purchase_cart_screen.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final cartItems = ref.watch(purchaseCartProvider);
    final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    final totalItems = cartItems.fold(0, (sum, item) => sum + item.quantity);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    void showAddToCartDialog(Product product) {
      showDialog(
        context: context,
        builder: (context) => AddToPurchaseCartDialog(product: product),
      );
    }

    Widget buildCartPanel() {
      return Material(
        elevation: 12,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$totalItems item', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    currencyFormatter.format(totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Lihat Keranjang & Proses'),
                  onPressed: cartItems.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PurchaseCartScreen()),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pembelian Baru'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          final filteredProducts = products
              .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          final paginatedProducts = filteredProducts
              .skip(_currentPage * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

          final totalPages = (filteredProducts.length / _itemsPerPage).ceil();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: paginatedProducts.length,
                  itemBuilder: (context, index) {
                    final product = paginatedProducts[index];
                    final cartItem = cartItems.firstWhere(
                      (item) => item.product.id == product.id,
                      orElse: () => PurchaseCartItem(product: product, quantity: 0, purchasePrice: 0),
                    );
                    final isInCart = cartItem.quantity > 0;

                    final lastPrice = product.lastPurchasePrice != null && product.lastPurchasePrice! > 0
                        ? currencyFormatter.format(product.lastPurchasePrice)
                        : 'N/A';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        child: (product.image != null && product.image!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  product.image!,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.shopping_bag_outlined, color: Colors.grey);
                                  },
                                ),
                              )
                            : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                      onTap: () => showAddToCartDialog(product),
                      title: Text(product.name),
                      subtitle: Text('Stok: ${product.stock} | Beli Terakhir: $lastPrice'),
                      trailing: isInCart
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    final currentQuantity = cartItem.quantity;
                                    if (currentQuantity > 1) {
                                      ref.read(purchaseCartProvider.notifier).updateQuantity(product.id, currentQuantity - 1);
                                    } else {
                                      ref.read(purchaseCartProvider.notifier).removeProduct(product.id);
                                    }
                                  },
                                ),
                                Text(cartItem.quantity.toString(), style: Theme.of(context).textTheme.titleMedium),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                      ref.read(purchaseCartProvider.notifier).updateQuantity(product.id, cartItem.quantity + 1);
                                  },
                                ),
                              ],
                            )
                          : const Icon(Icons.chevron_right, color: Colors.grey),
                    );
                  },
                ),
              ),
              if (totalPages > 1)
                _buildPaginationControls(totalPages),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi error: $err')),
      ),
      bottomNavigationBar: cartItems.isNotEmpty ? buildCartPanel() : null,
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text('Halaman ${_currentPage + 1} dari $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }
}
