import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import '../../models/purchase_transaction.dart';
import '../../providers/purchase_report_provider.dart';

// Definisikan class lokal untuk menampung data item yang bisa diedit.
class _EditableItem {
  final String productId;
  final String productName;
  int quantity;
  double purchasePrice;
  final String? imageUrl;

  _EditableItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    this.imageUrl,
  });
}

class EditPurchaseScreen extends ConsumerStatefulWidget {
  final PurchaseTransaction transaction;

  const EditPurchaseScreen({super.key, required this.transaction});

  @override
  ConsumerState<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends ConsumerState<EditPurchaseScreen> {
  late List<_EditableItem> _items;
  bool _isInitialized = false;
  bool _isSaving = false;
  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Inisialisasi item dilakukan setelah data gambar tersedia
  void _initializeItems(Map<String, String> productImages) {
    if (!_isInitialized) {
      _items = widget.transaction.items.map((item) {
        // Ambil imageUrl dari map productImages
        return _EditableItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          purchasePrice: item.purchasePrice,
          imageUrl: productImages[item.productId],
        );
      }).toList();
      _isInitialized = true;
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _items[index].quantity = newQuantity;
      });
    }
  }

  void _updatePrice(int index, double newPrice) {
    if (newPrice >= 0) {
      setState(() {
        _items[index].purchasePrice = newPrice;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalBaru {
    if (!_isInitialized) return 0;
    return _items.fold(0, (sum, item) => sum + (item.quantity * item.purchasePrice));
  }

  Future<void> _saveChanges() async {
    if (!_isInitialized) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedItems = _items.map((item) {
        return {
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'purchasePrice': item.purchasePrice,
          'subtotal': item.quantity * item.purchasePrice,
        };
      }).toList();

      final newTotalAmount = _totalBaru;

      await FirebaseFirestore.instance
          .collection('purchase_transactions')
          .doc(widget.transaction.id)
          .update({
        'items': updatedItems,
        'totalAmount': newTotalAmount,
      });

      // Refresh data di laporan
      ref.refresh(purchaseTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil diperbarui')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productImagesAsync = ref.watch(productImagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Transaksi #${widget.transaction.id.substring(0, 7)}...'),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.add_circle_outline),
            tooltip: 'Tambah Produk',
            onPressed: () {
              // TODO: Implementasi logika tambah produk
            },
          ),
        ],
      ),
      body: productImagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat data gambar: $err')),
        data: (images) {
          _initializeItems(images);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildEditableItemCard(item, index);
                  },
                ),
              ),
              _buildSummary(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableItemCard(_EditableItem item, int index) {
    final priceController = TextEditingController(text: item.purchasePrice.toStringAsFixed(0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Produk
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Ionicons.image_outline, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                // Nama dan Tombol Hapus
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      // Input Harga
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Harga Beli (Satuan)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onSubmitted: (value) => _updatePrice(index, double.tryParse(value) ?? item.purchasePrice),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Ionicons.trash_outline, color: Colors.redAccent),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kontrol Jumlah
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah', style: TextStyle(fontSize: 14)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Ionicons.remove_circle_outline), onPressed: () => _updateQuantity(index, item.quantity - 1)),
                    Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Ionicons.add_circle_outline), onPressed: () => _updateQuantity(index, item.quantity + 1)),
                  ],
                ),
                // Subtotal
                Text(
                  _currencyFormatter.format(item.quantity * item.purchasePrice),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Baru:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _currencyFormatter.format(_totalBaru),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
