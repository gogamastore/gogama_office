import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../providers/order_provider.dart';

class ValidatedOrderSummaryScreen extends ConsumerStatefulWidget {
  final Order originalOrder;
  final List<OrderItem> validatedItems;

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

  void _onConfirmAndProcess() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final newSubtotal = widget.validatedItems
        .fold(0.0, (sum, item) => sum + (item.quantity * item.price));
    final shippingCost = widget.originalOrder.shippingFee ?? 0;
    final newGrandTotal = newSubtotal + shippingCost;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final orderId = widget.originalOrder.id;
      final orderNotifier = ref.read(orderProvider.notifier);

      final success = await orderNotifier.updateOrder(
        orderId,
        widget.validatedItems,
        shippingCost,
        newGrandTotal, 
      );

      if (success) {
        await ref.read(orderServiceProvider).updateOrderStatus(orderId, 'processing');

        ref.invalidate(orderProvider);
        ref.invalidate(orderDetailsProvider(orderId));
        ref.invalidate(orderStatusCountsProvider);
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
                content: Text('Pesanan berhasil diproses dan siap dikirim.'),
                backgroundColor: Colors.green),
          );
          navigator.popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception('Gagal memperbarui detail pesanan.');
      }

    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Terjadi error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    final newSubtotal = widget.validatedItems
        .fold(0.0, (sum, item) => sum + (item.quantity * item.price));
    final shippingCost = widget.originalOrder.shippingFee ?? 0;
    final newGrandTotal = newSubtotal + shippingCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Pesanan Divalidasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // CATATAN: ConstrainedBox dihapus karena tidak lagi diperlukan dan berpotensi
        // menyebabkan masalah layout lain jika tidak digunakan dengan benar.
        // Column akan secara alami mengambil ruang yang dibutuhkan oleh anak-anaknya.
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
                    _buildSummaryRow(title: 'Subtotal', amount: newSubtotal, formatter: currencyFormatter),
                    const SizedBox(height: 8),
                    _buildSummaryRow(title: 'Ongkos Kirim', amount: shippingCost.toDouble(), formatter: currencyFormatter),
                    const Divider(),
                    _buildSummaryRow(
                      title: 'Grand Total',
                      amount: newGrandTotal,
                      formatter: currencyFormatter,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            // --- PERBAIKAN: Mengganti Spacer dengan SizedBox --- 
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : _onConfirmAndProcess,
                child: _isProcessing
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Text('Proses Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            // Menambahkan sedikit ruang di bawah agar tidak terlalu mepet dengan tepi bawah layar
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String title,
    required double amount,
    required NumberFormat formatter,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
