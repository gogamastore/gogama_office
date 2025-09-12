import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart'; // Impor provider produk

class ProcessPurchaseScreen extends ConsumerStatefulWidget {
  const ProcessPurchaseScreen({super.key});

  @override
  _ProcessPurchaseScreenState createState() => _ProcessPurchaseScreenState();
}

class _ProcessPurchaseScreenState extends ConsumerState<ProcessPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  String _paymentMethod = 'Tunai';
  DateTime _purchaseDate = DateTime.now();

  Future<void> _processPurchase() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final cartItems = ref.read(purchaseCartProvider);
      final totalAmount = ref.read(purchaseCartProvider.notifier).totalAmount;
      
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih supplier.')),
        );
        return;
      }

      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final purchaseNotifier = ref.read(purchaseCartProvider.notifier);
      final productService = ref.read(productServiceProvider); // Dapatkan service produk
      
      try {
        // 1. Catat pembelian utama
        await ref.read(purchaseServiceProvider).recordPurchase(
              supplierId: _selectedSupplier!.id,
              supplierName: _selectedSupplier!.name,
              purchaseDate: Timestamp.fromDate(_purchaseDate),
              items: cartItems,
              totalAmount: totalAmount,
              paymentMethod: _paymentMethod,
            );

        // 2. Perbarui harga beli terakhir untuk setiap produk
        for (final item in cartItems) {
          final updatedProduct = item.product.copyWith(lastPurchasePrice: item.purchasePrice);
          await productService.updateProduct(updatedProduct);
        }

        // 3. Bersihkan keranjang & beri notifikasi
        purchaseNotifier.clearCart();
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Pembelian berhasil dicatat & harga produk diperbarui.')),
        );
        navigator.pop(); // Kembali ke halaman sebelumnya

      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal memproses pembelian: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(purchaseCartProvider);
    final totalAmount = ref.watch(purchaseCartProvider.notifier).totalAmount;
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Proses Pembelian')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan Pesanan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.quantity} x @${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(item.purchasePrice)}'),
                      trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(item.subtotal)),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text('Total', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                trailing: Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp').format(totalAmount),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 32),

              Text('Detail Transaksi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              suppliersAsync.when(
                data: (suppliers) => DropdownButtonFormField<Supplier>(
                  decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()),
                  items: suppliers.map((supplier) {
                    return DropdownMenuItem<Supplier>(
                      value: supplier,
                      child: Text(supplier.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedSupplier = value),
                  validator: (value) => value == null ? 'Pilih supplier' : null,
                  initialValue: _selectedSupplier,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: DateFormat('dd MMMM yyyy').format(_purchaseDate)),
                decoration: InputDecoration(
                  labelText: 'Tanggal Pembelian',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Metode Pembayaran', border: OutlineInputBorder()),
                items: ['Tunai', 'Transfer Bank', 'Lainnya'].map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
                initialValue: _paymentMethod,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: cartItems.isEmpty ? null : _processPurchase,
          child: const Text('Selesaikan Pembelian'),
        ),
      ),
    );
  }
}
