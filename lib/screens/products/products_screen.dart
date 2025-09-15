import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../stock/stock_management_screen.dart'; // Impor halaman baru
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        // TODO: Implement import functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur import akan segera hadir!')),
        );
        break;
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
            onSelected: _onMenuSelected, // Hubungkan ke fungsi navigasi
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
            final searchLower = _searchTerm.toLowerCase();
            return nameLower.contains(searchLower);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan.'))
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
          subtitle: Text(currencyFormatter.format(product.price)),
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
