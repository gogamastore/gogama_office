import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../models/order_item.dart'; // Impor OrderItem
import '../../models/order_product.dart';
import '../../providers/order_provider.dart';

class ValidatedOrderSummaryScreen extends ConsumerStatefulWidget {
  final Order originalOrder;
  final List<OrderProduct> validatedItems;

  const ValidatedOrderSummaryScreen({
    super.key,
    required this.originalOrder,
    required this.validatedItems,
  });

  @override
  ConsumerState<ValidatedOrderSummaryScreen> createState() =>
      _ValidatedOrderSummaryScreenState();
}

class _ValidatedOrderSummaryScreenState
    extends ConsumerState<ValidatedOrderSummaryScreen> {
  bool _isProcessing = false;

  void _onConfirm() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final newTotal = widget.validatedItems
        .fold(0.0, (sum, item) => sum + (item.quantity * item.price));

    // --- PERBAIKAN: Konversi OrderProduct ke OrderItem sebelum update ---
    final orderItems = widget.validatedItems.map((p) => OrderItem(
      productId: p.productId,
      name: p.name,
      quantity: p.quantity,
      price: p.price,
      // Properti seperti SKU dan imageUrl tidak diperlukan untuk update
    )).toList();

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Panggil provider dengan List<OrderItem>
      final success = await ref.read(orderProvider.notifier).updateOrder(
            widget.originalOrder.id,
            orderItems, // Gunakan list yang sudah dikonversi
            widget.originalOrder.shippingFee ?? 0,
            newTotal,
          );

      if (success && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Pesanan berhasil divalidasi dan diperbarui.'),
              backgroundColor: Colors.green),
        );
        navigator.popUntil((route) => route.isFirst);
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Gagal memperbarui pesanan.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Terjadi error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final newTotal = widget.validatedItems
        .fold(0.0, (sum, item) => sum + (item.quantity * item.price));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Pesanan Divalidasi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan Baru',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nomor Pesanan:', style: TextStyle(color: Colors.grey[600])),
                          Text(widget.originalOrder.id,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                    const Divider(height: 24),
                    ...widget.validatedItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${item.quantity} x ${currencyFormatter.format(item.price)}'),
                            trailing: Text(
                                currencyFormatter.format(item.quantity * item.price), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Baru:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(currencyFormatter.format(newTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green)),
                        ]),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : _onConfirm,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Konfirmasi & Perbarui Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
