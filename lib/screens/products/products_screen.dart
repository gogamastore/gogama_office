
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/product_provider.dart';
import '../../models/product.dart';

// --- UBAH MENJADI CONSUMER STATEFUL WIDGET ---
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  // --- TAMBAHKAN STATE UNTUK PENCARIAN ---
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildActionBar(),
            // --- BERI FUNGSI PADA KOTAK PENCARIAN ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama atau SKU produk...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8C8D)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // --- LOGIKA FILTER PENCARIAN ---
                  final filteredProducts = products.where((product) {
                    final nameLower = product.name.toLowerCase();
                    final skuLower = (product.sku ?? '').toLowerCase();
                    final searchLower = _searchQuery.toLowerCase();
                    return nameLower.contains(searchLower) || skuLower.contains(searchLower);
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('Produk tidak ditemukan.'));
                  }
                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
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

  // ... (widget buildHeader dan buildActionBar tetap sama) ...
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
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () { /* TODO: Implement Import Modal */ },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Impor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5DADE2),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () { /* TODO: Navigate to Stock Management Screen */ },
            icon: const Icon(Icons.archive, size: 16),
            label: const Text('Manajemen Stok'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5DADE2),
            ),
          ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: (product.image != null && product.image!.isNotEmpty)
                  ? Image.network(
                      product.image!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFE0E6ED),
                      child: const Icon(Icons.image_not_supported, color: Color(0xFFBDC3C7)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.sku != null && product.sku!.isNotEmpty)
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currencyFormatter.format(product.price),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 2),
                if (product.purchasePrice != null && product.purchasePrice! > 0)
                  Text(
                    'Beli: ${currencyFormatter.format(product.purchasePrice)} ',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Stok: ${product.stock}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF3498DB), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_outlined, color: Color(0xFF5DADE2)),
              onPressed: () { /* TODO: Open Edit Product Modal */ },
            ),
          ],
        ),
      ),
    );
  }
}
