import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/sound_service.dart'; // DIPERBARUI: Impor SoundService
import '../stock/stock_management_screen.dart'; 
import 'add_product_screen.dart';
import 'barcode_scanner_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // DIPERBARUI: Buat instance SoundService
  late final SoundService _soundService;

  @override
  void initState() {
    super.initState();
    _soundService = SoundService(); // Inisialisasi SoundService

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchTerm = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _soundService.dispose(); // DIPERBARUI: Hapus SoundService
    super.dispose();
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'stock_management':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const StockManagementScreen()),
        );
        break;
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur import akan segera hadir!')),
        );
        break;
    }
  }

  // DIPERBARUI: Menggunakan SoundService untuk memutar suara
  Future<void> _navigateToScanner() async {
    final sku = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (sku != null && mounted) {
      _searchController.text = sku;
      // Memutar suara sukses dengan aman menggunakan service
      await _soundService.playSuccessSound();
    } else {
      // Opsional: Memutar suara error jika pemindai dibatalkan
      await _soundService.playErrorSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = ref.watch(allProductsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: Text('Import Produk'),
              ),
              const PopupMenuItem<String>(
                value: 'stock_management',
                child: Text('Manajemen Stok'),
              ),
            ],
          ),
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) {
          final filteredProducts = products.where((product) {
            final nameLower = product.name.toLowerCase();
            final skuLower = product.sku?.toLowerCase() ?? '';
            final searchLower = _searchTerm.toLowerCase();
            
            return nameLower.contains(searchLower) || skuLower.contains(searchLower);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk atau pindai SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Ionicons.barcode_outline),
                      onPressed: _navigateToScanner,
                      tooltip: 'Pindai Barcode',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(child: Text(_searchTerm.isEmpty ? 'Tidak ada produk.' : 'Produk tidak ditemukan.'))
                    : _buildProductList(filteredProducts, currencyFormatter),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        tooltip: 'Tambah Produk',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, NumberFormat currencyFormatter) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE0E6ED),
            backgroundImage: (product.image != null && product.image!.isNotEmpty)
              ? NetworkImage(product.image!)
              : null,
            child: (product.image == null || product.image!.isEmpty)
              ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF34495E))
              : null,
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currencyFormatter.format(product.price)),
              if (product.sku != null && product.sku!.isNotEmpty)
                Text('SKU: ${product.sku}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          trailing: Text('Stok: ${product.stock}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
}
