
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../providers/order_provider.dart';
import 'add_product_to_order_dialog.dart';

// Ini adalah halaman baru, menggantikan AlertDialog sebelumnya
class EditOrderScreen extends ConsumerStatefulWidget {
  final Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  late List<OrderProduct> _products;
  late TextEditingController _shippingFeeController;
  double _subtotal = 0;
  double _total = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Buat salinan yang bisa diubah
    _products = List<OrderProduct>.from(widget.order.products);
    _shippingFeeController = TextEditingController(text: widget.order.shippingFee.toStringAsFixed(0));
    _calculateTotals();
  }

  void _calculateTotals() {
    _subtotal = _products.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final shippingFee = double.tryParse(_shippingFeeController.text) ?? 0.0;
    setState(() {
      _total = _subtotal + shippingFee;
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _products[index] = _products[index].copyWith(quantity: newQuantity);
        _calculateTotals();
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
      _calculateTotals();
    });
  }

  void _addProduct() async {
    final newProduct = await showDialog<OrderProduct>(
      context: context,
      builder: (context) => AddProductToOrderDialog(
        existingProducts: _products,
      ),
    );

    if (newProduct != null) {
      setState(() {
        final existingIndex = _products.indexWhere((p) => p.productId == newProduct.productId);
        if (existingIndex != -1) {
          _products[existingIndex] = _products[existingIndex].copyWith(quantity: _products[existingIndex].quantity + newProduct.quantity);
        } else {
          _products.add(newProduct);
        }
        _calculateTotals();
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final shippingFee = double.tryParse(_shippingFeeController.text) ?? 0.0;
    
    // Panggil metode notifier, bukan service langsung
    final success = await ref.read(orderProvider.notifier).updateOrder(
      widget.order.id,
      _products,
      shippingFee,
      _total,
    );
    
    // Guard dengan 'mounted' check
    if (!mounted) return;

    if (success) {
      // Invalidate provider yang relevan untuk refresh data
      ref.invalidate(orderProvider);
      ref.invalidate(orderDetailsProvider(widget.order.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil diperbarui!')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan perubahan.')));
    }

    if(mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Pesanan #${widget.order.id.substring(0, 7)}...'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
              tooltip: 'Simpan Perubahan',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        label: const Text('Tambah Produk'),
        icon: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductListSection(),
            const SizedBox(height: 24),
            _buildTotalsSection(formatter),
            const SizedBox(height: 80), // Ruang untuk FAB
          ],
        ),
      ),
    );
  }

  Widget _buildProductListSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Item Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_products.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('Tidak ada produk dalam pesanan.'),
              )),
            if (_products.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    // FIX: Gunakan 'name' bukan 'productName'
                    title: Text(product.name),
                    subtitle: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuantityEditor(index, product.quantity),
                        IconButton(
                          icon: const Icon(Ionicons.trash_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeProduct(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityEditor(int index, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Ionicons.remove_circle_outline, size: 22, color: Colors.black54),
          onPressed: () => _updateQuantity(index, quantity - 1),
          splashRadius: 20,
        ),
        SizedBox(
          width: 30,
          child: Text(quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ),
        IconButton(
          icon: const Icon(Ionicons.add_circle_outline, size: 22, color: Colors.blue),
          onPressed: () => _updateQuantity(index, quantity + 1),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildTotalsSection(NumberFormat formatter) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Detail Biaya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _shippingFeeController,
              decoration: const InputDecoration(
                labelText: 'Biaya Pengiriman',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotals(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal Produk:', style: TextStyle(fontSize: 16)),
                Text(formatter.format(_subtotal), style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Akhir:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  formatter.format(_total),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
