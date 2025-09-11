import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../utils/formatter.dart';
// HAPUS DIALOG LAMA, GUNAKAN HALAMAN BARU
import './edit_order_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          orderAsync.when(
            data: (order) {
              if (order == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Ionicons.create_outline),
                tooltip: 'Edit Pesanan',
                // --- PERUBAHAN UTAMA DI SINI ---
                onPressed: () {
                  // Ganti showDialog menjadi Navigator.push
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditOrderScreen(order: order),
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }
          return _buildOrderDetailsView(context, ref, order);
        },
      ),
    );
  }

  Widget _buildOrderDetailsView(BuildContext context, WidgetRef ref, Order order) {
    return ListView(
      padding: const EdgeInsets.all(12.0),
      children: [
        _buildInfoCard(order),
        const SizedBox(height: 12),
        _buildCustomerCard(order),
        const SizedBox(height: 12),
        _buildProductsCard(order),
        const SizedBox(height: 12),
        _buildPaymentInfoCard(context, order),
        const SizedBox(height: 12),
        _buildShippingInfoCard(order),
        const SizedBox(height: 20),
        _buildCancelButton(context, ref, order),
      ],
    );
  }

  Widget _buildInfoCard(Order order) {
    return _buildCard(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'No. Pesanan ${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: getStatusColor(order.status).withOpacity(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getStatusText(order.status),
                style: TextStyle(fontWeight: FontWeight.bold, color: getStatusColor(order.status), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(order.date.toDate()),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Order order) {
    return _buildCard(
      children: [
        const Text('Detail Pelanggan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        _buildCustomerDetailRow(Ionicons.person_outline, order.customer),
        _buildCustomerDetailRow(Ionicons.call_outline, order.customerPhone),
        _buildCustomerDetailRow(Ionicons.location_outline, order.customerAddress, isLast: true),
      ],
    );
  }

  Widget _buildCustomerDetailRow(IconData icon, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildProductsCard(Order order) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final subtotal = order.products.fold(0.0, (sum, p) => sum + (p.price * p.quantity));

    return _buildCard(
      children: [
        const Text('Produk Dipesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        ...order.products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${p.quantity} x ${formatter.format(p.price)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(formatter.format(p.price * p.quantity), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
        const Divider(height: 20),
        _buildSummaryRow('Subtotal', subtotal),
        const SizedBox(height: 8),
        _buildSummaryRow('Ongkos Kirim', order.shippingFee ?? 0),
        const SizedBox(height: 12),
        _buildSummaryRow('Total', double.tryParse(order.total) ?? 0.0, isTotal: true),
      ],
    );
  }

  Widget _buildPaymentInfoCard(BuildContext context, Order order) {
    return _buildCard(
      children: [
        const Text('Informasi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status', style: TextStyle(fontSize: 15, color: Colors.grey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: getPaymentStatusColor(order.paymentStatus).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                getPaymentStatusText(order.paymentStatus),
                style: TextStyle(fontWeight: FontWeight.bold, color: getPaymentStatusColor(order.paymentStatus)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Metode', style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                order.paymentMethod,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (order.paymentProofUrl != null && order.paymentProofUrl!.isNotEmpty)
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Ionicons.receipt_outline, size: 18),
              label: const Text('Lihat Bukti Pembayaran'),
              onPressed: () async {
                final Uri url = Uri.parse(order.paymentProofUrl!);
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal membuka URL.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                elevation: 0,
              ),
            ),
          )
        else
          const Center(
            child: Text('Bukti pembayaran belum diunggah.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildShippingInfoCard(Order order) {
    return _buildCard(
      children: [
        const Text('Info Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        Row(
          children: [
            Icon(Ionicons.cube_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(order.shippingMethod, style: const TextStyle(fontSize: 15))),
          ],
        )
      ],
    );
  }
  
  Widget _buildSummaryRow(String title, num value, {bool isTotal = false}) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isTotal ? 18 : 15, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(formatter.format(value), style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, WidgetRef ref, Order order) {
    if (order.status == 'pending' || order.status == 'processing') {
      return ElevatedButton.icon(
        icon: const Icon(Ionicons.close_circle_outline, color: Colors.white),
        label: const Text('Batalkan Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          // Logika untuk membatalkan pesanan
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
