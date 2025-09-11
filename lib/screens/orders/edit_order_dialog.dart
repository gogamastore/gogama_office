
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../providers/order_provider.dart';
import './add_product_to_order_dialog.dart';

class EditOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const EditOrderDialog({super.key, required this.order});

  @override
  _EditOrderDialogState createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends ConsumerState<EditOrderDialog> {
  // Data di sini sudah dijamin bersih oleh model `OrderProduct.fromJson`
  late List<OrderProduct> _products;
  late TextEditingController _shippingFeeController;
  late double _subtotal;
  late double _total;

  @override
  void initState() {
    super.initState();
    // Cukup salin daftar produk. Model sudah membersihkan data saat dibaca.
    _products = List<OrderProduct>.from(widget.order.products);
    _shippingFeeController = TextEditingController(text: widget.order.shippingFee?.toStringAsFixed(0) ?? '0');
    _calculateTotals();
  }

  // Logika kalkulasi kembali sederhana karena data sudah dijamin bersih.
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

  void _showAddProductDialog() async {
    final List<OrderProduct>? newProducts = await showDialog(
      context: context,
      builder: (context) => AddProductToOrderDialog(existingProducts: _products),
    );

    if (newProducts != null && newProducts.isNotEmpty) {
      setState(() {
        // Produk baru yang ditambahkan juga sudah dijamin bersih oleh modelnya.
        _products.addAll(newProducts);
        _calculateTotals();
      });
    }
  }

  void _saveChanges() async {
    final newShippingFee = double.tryParse(_shippingFeeController.text) ?? 0.0;

    // Tidak perlu lagi pembersihan manual. Data sudah konsisten.
    final success = await ref.read(orderProvider.notifier).updateOrder(
      widget.order.id,
      _products, // Langsung kirim daftar yang sudah bersih sejak awal.
      newShippingFee,
      _total,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AlertDialog(
      title: Text('Edit Pesanan #${widget.order.id.substring(0, 7)}...'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ubah jumlah, hapus item, atau tambah produk baru ke pesanan.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Produk')),
                    DataColumn(label: Text('Jumlah'), numeric: true),
                    DataColumn(label: Text('Hapus')), 
                  ],
                  rows: _products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(product.name, softWrap: true)),
                        DataCell(_buildQuantityEditor(index, product.quantity)),
                        DataCell(IconButton(icon: const Icon(Ionicons.trash_outline, color: Colors.red), onPressed: () => _removeProduct(index))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Ionicons.add),
                label: const Text('Tambah Produk Baru'),
              ),
            ),
            const Divider(height: 24),
            _buildTotalsSection(currencyFormatter),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Simpan Perubahan')),
      ],
    );
  }
  
  Widget _buildQuantityEditor(int index, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Ionicons.remove_circle_outline, size: 20), onPressed: () => _updateQuantity(index, quantity - 1)),
        Text(quantity.toString()),
        IconButton(icon: const Icon(Ionicons.add_circle_outline, size: 20), onPressed: () => _updateQuantity(index, quantity + 1)),
      ],
    );
  }
  
  Widget _buildTotalsSection(NumberFormat formatter) {
    return Column(
      children: [
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
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal Produk:'), Text(formatter.format(_subtotal))]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(formatter.format(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
      ],
    );
  }
}
