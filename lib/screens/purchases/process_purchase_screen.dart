import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/supplier.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../services/purchase_service.dart';

class ProcessPurchaseScreen extends ConsumerStatefulWidget {
  const ProcessPurchaseScreen({super.key});

  @override
  ProcessPurchaseScreenState createState() => ProcessPurchaseScreenState();
}

class ProcessPurchaseScreenState extends ConsumerState<ProcessPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Supplier? _selectedSupplier;
  String _paymentMethod = 'cash'; // Default payment method

  // Loading state for purchase process
  bool _isProcessing = false;

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate() || _isProcessing) {
      return;
    }

    final cartItems = ref.read(purchaseCartProvider);
    final totalAmount = ref.read(purchaseTotalProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (cartItems.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Keranjang tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Panggil service baru yang menggunakan WriteBatch
      await PurchaseService().processPurchaseTransaction(
        items: cartItems,
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        supplier: _selectedSupplier,
      );

      // Kosongkan keranjang setelah berhasil
      ref.read(purchaseCartProvider.notifier).clearCart();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Transaksi pembelian berhasil diproses dan disimpan!')),
      );
      
      // Kembali ke halaman sebelumnya
      navigator.pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal memproses transaksi: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Proses Pembelian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: const Color(0xFF2C3E50),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildDetailsSection()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildSummarySection(currencyFormatter)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildDetailsSection(),
                      const SizedBox(height: 16),
                      _buildSummarySection(currencyFormatter),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final suppliersAsync = ref.watch(supplierProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Detail Supplier & Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const Divider(height: 32),

            const Text('Supplier', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            suppliersAsync.when(
              data: (suppliers) => DropdownButtonFormField<Supplier>(
                initialValue: _selectedSupplier,
                hint: const Text('Pilih Supplier (Opsional)'),
                items: suppliers.map((supplier) {
                  return DropdownMenuItem<Supplier>(
                    value: supplier,
                    child: Text(supplier.name),
                  );
                }).toList(),
                onChanged: (Supplier? newValue) {
                  setState(() {
                    _selectedSupplier = newValue;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Gagal memuat supplier: $err'),
            ),
            const SizedBox(height: 24),

            const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
             RadioMenuButton<String>(
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (String? value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              child: const Text('Cash'),
            ),
            RadioMenuButton<String>(
              value: 'bank_transfer',
              groupValue: _paymentMethod,
              onChanged: (String? value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              child: const Text('Bank Transfer'),
            ),
            RadioMenuButton<String>(
              value: 'credit',
              groupValue: _paymentMethod,
              onChanged: (String? value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              child: const Text('Credit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(NumberFormat currencyFormatter) {
    final cartItems = ref.watch(purchaseCartProvider);
    final totalAmount = ref.watch(purchaseTotalProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('2. Ringkasan Pembelian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const Divider(height: 32),
            if (cartItems.isEmpty)
              const Center(child: Text('Keranjang kosong.'))
            else
              ...cartItems.map((item) => ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('${item.quantity} x ${currencyFormatter.format(item.purchasePrice)}'),
                    trailing: Text(currencyFormatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w500)),
                  )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembelian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(currencyFormatter.format(totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
              ],
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: cartItems.isNotEmpty ? _processTransaction : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi & Simpan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  disabledBackgroundColor: Colors.grey,
                ),
              )
          ],
        ),
      ),
    );
  }
}
