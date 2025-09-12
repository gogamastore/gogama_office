
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import 'edit_product_screen.dart'; // Impor halaman edit

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  // Navigasi ke halaman edit dan tunggu halamannya ditutup
  void _navigateToEditScreen() async {
    // PERBAIKAN: Hapus variabel 'result' yang tidak digunakan.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: _currentProduct),
      ),
    );

    // Karena kita menggunakan Riverpod untuk state management, kita tidak perlu 
    // secara manual memperbarui state di sini. Provider akan secara otomatis 
    // memperbarui UI di seluruh aplikasi saat data di Firestore berubah.
  }


  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProduct.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit), 
            tooltip: 'Edit Produk',
            onPressed: _navigateToEditScreen, // <-- PANGGIL FUNGSI NAVIGASI
          ),
          IconButton(
            icon: const Icon(Icons.history), 
            tooltip: 'Lihat Log Stok',
            onPressed: () { /* TODO: Implement Log History */ },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline), 
            tooltip: 'Hapus Produk',
            onPressed: () { /* TODO: Implement Delete Logic */ },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildInfoSection(currencyFormatter),
            const Divider(height: 40, thickness: 1),
            _buildDescriptionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Hero(
        tag: 'product-image-${_currentProduct.id}', // Tag unik untuk animasi
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: (_currentProduct.image != null && _currentProduct.image!.isNotEmpty)
              ? Image.network(
                  _currentProduct.image!,
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: const Color(0xFFE0E6ED),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Color(0xFFBDC3C7), size: 80),
      ),
    );
  }

  Widget _buildInfoSection(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentProduct.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        if (_currentProduct.sku != null && _currentProduct.sku!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'SKU: ${_currentProduct.sku}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoTile(
              title: 'Harga Jual',
              value: currencyFormatter.format(_currentProduct.price),
              valueColor: const Color(0xFF2980B9),
            ),
            _buildInfoTile(
              title: 'Stok Saat Ini',
              value: _currentProduct.stock.toString(),
              valueColor: _currentProduct.stock > 10 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
              isRightAligned: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile({required String title, required String value, Color? valueColor, bool isRightAligned = false}) {
    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        Text(
          (_currentProduct.description != null && _currentProduct.description!.isNotEmpty)
              ? _currentProduct.description!
              : 'Tidak ada deskripsi untuk produk ini.',
          style: const TextStyle(fontSize: 16, color: Color(0xFF34495E), height: 1.5),
        ),
      ],
    );
  }
}
