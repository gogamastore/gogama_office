
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/order_product.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class AddProductToOrderDialog extends ConsumerStatefulWidget {
  final List<OrderProduct> existingProducts;

  const AddProductToOrderDialog({super.key, required this.existingProducts});

  @override
  _AddProductToOrderDialogState createState() => _AddProductToOrderDialogState();
}

class _AddProductToOrderDialogState extends ConsumerState<AddProductToOrderDialog> {
  final List<Product> _selectedProducts = [];
  // --- TAMBAHKAN STATE UNTUK PENCARIAN ---
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(allProductsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Tambah Produk ke Pesanan'),
      // --- BUAT KONTEN MENJADI COLUMN UNTUK MENAMPUNG PENCARIAN ---
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TAMBAHKAN KOTAK PENCARIAN ---
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama produk...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true, // Membuat field lebih ringkas
                ),
              ),
            ),
            // --- DAFTAR PRODUK YANG BISA DI-SCROLL ---
            Expanded(
              child: allProductsAsync.when(
                data: (allProducts) {
                  final existingProductIds = widget.existingProducts.map((p) => p.productId).toSet();
                  // --- LOGIKA FILTER BERDASARKAN PENCARIAN ---
                  final availableProducts = allProducts.where((p) {
                    final isNotExisting = !existingProductIds.contains(p.id);
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    return isNotExisting && matchesSearch;
                  }).toList();

                  if (availableProducts.isEmpty) {
                    return const Center(
                      child: Text('Produk tidak ditemukan atau sudah ditambahkan.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableProducts.length,
                    itemBuilder: (context, index) {
                      final product = availableProducts[index];
                      final isSelected = _selectedProducts.contains(product);

                      return CheckboxListTile(
                        title: Text(product.name),
                        subtitle: Text('Stok: ${product.stock}  |  ${currencyFormatter.format(product.price)}'),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedProducts.add(product);
                            } else {
                              _selectedProducts.remove(product);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final newOrderProducts = _selectedProducts.map((p) => OrderProduct(
              productId: p.id,
              name: p.name,
              price: p.price,
              quantity: 1,
            )).toList();
            Navigator.of(context).pop(newOrderProducts);
          },
          child: const Text('Tambahkan'),
        ),
      ],
    );
  }
}
