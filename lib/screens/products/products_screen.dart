// lib/screens/products/products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/product_provider.dart';
import '../../models/product.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildActionBar(),
            _buildSearchBar(),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductItem(context, product);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Produk',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          SizedBox(height: 4),
          Text(
            'Kelola produk Anda dan lihat performa penjualannya.',
            style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Impor
          ElevatedButton.icon(
            onPressed: () { /* TODO: Implement Import Modal */ },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Impor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5DADE2),
            ),
          ),
          // Tombol Manajemen Stok
          ElevatedButton.icon(
            onPressed: () { /* TODO: Navigate to Stock Management Screen */ },
            icon: const Icon(Icons.archive, size: 16),
            label: const Text('Manajemen Stok'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5DADE2),
            ),
          ),
          // Tombol Tambah Produk
          ElevatedButton.icon(
            onPressed: () { /* TODO: Open Add Product Modal */ },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Produk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5DADE2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8C8D)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gambar Produk
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: (product.image != null && product.image!.isNotEmpty)
                  ? Image.network(
                      product.image!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFE0E6ED),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFE0E6ED),
                          child: const Icon(Icons.broken_image, color: Color(0xFFBDC3C7)),
                        );
                      },
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFE0E6ED),
                      child: const Icon(Icons.image_not_supported, color: Color(0xFFBDC3C7)),
                    ),
            ),
            const SizedBox(width: 12),
            // Informasi Produk
            Flexible(
              child: Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                    ),
                  ],
                ),
              ),
            ),
            // Stok dan Harga
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stok: ${product.stock}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga Beli: ${currencyFormatter.format(product.purchasePrice)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                ),
                Text(
                  'Harga Jual: ${product.price}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            // Tombol Aksi
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF5DADE2)),
              onPressed: () { /* TODO: Open Edit Product Modal */ },
            ),
          ],
        ),
      ),
    );
  }
}
