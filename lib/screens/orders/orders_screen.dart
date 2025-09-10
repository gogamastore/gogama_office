import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../providers/order_provider.dart';
import '../../models/order.dart';
import './order_detail_screen.dart'; // Import halaman detail

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(orderFilterProvider);
    // PERBAIKAN: Langsung watch provider yang sudah disederhanakan.
    final statusCounts = ref.watch(orderStatusCountsProvider);
    final allOrdersAsync = ref.watch(orderProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textTheme),
            _buildSearchBar(),
            // PERBAIKAN: Widget filter sekarang menggunakan data langsung dari statusCounts.
            // Kondisi loading/error dari `orderProvider` akan secara otomatis meng-handle ini.
            _buildFiltersContainer(context, ref, statusCounts),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(orderProvider.notifier).refresh(),
                child: allOrdersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Terjadi Kesalahan: $err')),
                  data: (allOrders) {
                    final filteredOrders = ref.watch(filteredOrdersProvider(activeFilter));
                    
                    if (filteredOrders.isEmpty) {
                      return _buildEmptyState(activeFilter);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(context, ref, order);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesanan',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lihat dan kelola semua pesanan yang masuk berdasarkan statusnya.',
            style: textTheme.bodySmall?.copyWith(color: const Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan nama customer atau nomor pesanan...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7F8C8D)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFiltersContainer(BuildContext context, WidgetRef ref, Map<String, int> counts) {
    final activeFilter = ref.watch(orderFilterProvider);
    final statusFilters = [
      {'key': 'pending', 'label': 'Belum Proses'},
      {'key': 'processing', 'label': 'Perlu Dikirim'},
      {'key': 'shipped', 'label': 'Dikirim'},
      {'key': 'delivered', 'label': 'Selesai'},
      {'key': 'cancelled', 'label': 'Dibatalkan'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusFilters.map((filter) {
            final key = filter['key']!;
            final label = filter['label']!;
            final count = counts[key] ?? 0;
            final isActive = activeFilter == key;

            return GestureDetector(
              onTap: () => ref.read(orderFilterProvider.notifier).state = key,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF5DADE2) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? const Color(0xFF5DADE2) : const Color(0xFFE0E6ED)),
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: isActive ? const Color(0xFF5DADE2) : const Color(0xFF7F8C8D),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Order order) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final double totalValue = double.tryParse(order.total.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: order.id),
          ),
        ).then((_) => ref.read(orderProvider.notifier).refresh()); // Refresh setelah kembali dari detail
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('No. Pesanan ${order.id}', style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
                        const SizedBox(height: 2),
                        Text(DateFormat('dd/MM/yy, HH:mm').format(order.date.toDate()), style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(order.status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.products.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(left: 4.0), 
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          ...order.products.take(2).map((p) => 
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text('• ${p.name} (${p.quantity}x)', style: const TextStyle(fontSize: 14, color: Color(0xFF34495E), height: 1.4), overflow: TextOverflow.ellipsis, maxLines: 1),
                              )
                          ),
                          if (order.products.length > 2)
                              Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text('... dan ${order.products.length - 2} produk lainnya', style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontStyle: FontStyle.italic)),
                              ),
                      ],
                  ),
              ),
              const SizedBox(height: 12),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                      Row(
                          children: [
                              Container(
                                  width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _getPaymentStatusColor(order.paymentStatus)),
                              ),
                              const SizedBox(width: 6),
                              Text(_getPaymentStatusText(order.paymentStatus), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getPaymentStatusColor(order.paymentStatus))),
                          ],
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                          const Text('Total Pesanan', style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D))),
                          const SizedBox(height: 2),
                          Text(currencyFormatter.format(totalValue), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          ],
                      ),
                  ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(thickness: 1, height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: order.paymentProofUrl != null ? () { /* Logika lihat bukti bayar */ } : null,
                      icon: Icon(Ionicons.receipt_outline, color: order.paymentProofUrl != null ? const Color(0xFF3498DB) : Colors.grey, size: 18),
                      label: Text('Bukti Bayar', style: TextStyle(fontWeight: FontWeight.bold, color: order.paymentProofUrl != null ? const Color(0xFF3498DB) : Colors.grey)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        String nextStatus = '';
                        if (order.status == 'pending') nextStatus = 'processing';
                        if (order.status == 'processing') nextStatus = 'shipped';

                        if (nextStatus.isNotEmpty) {
                          ref.read(orderServiceProvider).updateOrderStatus(order.id, nextStatus).then((_) {
                            ref.read(orderProvider.notifier).refresh();
                          });
                        }
                      },
                      icon: const Icon(Ionicons.arrow_forward_circle_outline, color: Colors.white, size: 18),
                      label: Text(_getButtonText(order.status), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DADE2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String activeFilter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Ionicons.file_tray_outline, size: 64, color: Color(0xFFBDC3C7)),
            const SizedBox(height: 16),
            const Text('Tidak Ada Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            Text('Saat ini tidak ada pesanan untuk kategori \'${_getStatusText(activeFilter)}\'.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
          ],
        ),
      ),
    );
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'pending':
        return 'Proses Pesanan';
      case 'processing':
        return 'Kirim Pesanan';
      default:
        return 'Detail'; 
    }
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return const Color(0xFF27AE60);
      case 'shipped': return const Color(0xFF3498DB);   
      case 'processing': return const Color(0xFFF39C12); 
      case 'pending': return const Color(0xFFE74C3C);   
      case 'cancelled': return const Color(0xFF95A5A6); 
      default: return const Color(0xFF7F8C8D);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'delivered': return 'Selesai';
      case 'shipped': return 'Dikirim';
      case 'processing': return 'Perlu Dikirim';
      case 'pending': return 'Belum Proses';
      case 'cancelled': return 'Dibatalkan';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return const Color(0xFF27AE60);     
      case 'unpaid': return const Color(0xFFE74C3C);    
      case 'partial': return const Color(0xFFF39C12);    
      default: return const Color(0xFF7F8C8D); 
    }
  }

  String _getPaymentStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return 'Lunas';
      case 'unpaid': return 'Belum Lunas';
      case 'partial': return 'Sebagian';
      default: return 'N/A';
    }
  }
}
