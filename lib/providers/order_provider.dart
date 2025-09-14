import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/order_item.dart';
// PERBAIKAN: Hapus impor yang tidak perlu karena tidak ada konversi
// import '../models/order_product.dart'; 
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderService _orderService;

  OrderNotifier(this._orderService) : super(const AsyncValue.loading()) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _orderService.getAllOrders();
      if (mounted) state = AsyncValue.data(orders);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    await _fetchOrders();
  }

  // PERBAIKAN FINAL: Menghapus konversi yang tidak perlu.
  // Metode ini sekarang hanya menyalurkan data yang sudah konsisten.
  Future<bool> updateOrder(String orderId, List<OrderItem> products, double shippingFee, double newTotal) async {
    try {
      // Panggil service langsung dengan List<OrderItem>.
      await _orderService.updateOrderDetails(orderId, products, shippingFee, newTotal);
      await refresh();
      return true;
    } catch (e, s) {
      log('Gagal memperbarui pesanan', error: e, stackTrace: s);
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(ref.watch(orderServiceProvider));
});

// ... (sisa kode provider tidak berubah)

final orderStatusCountsProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final orders = ref.watch(orderProvider).value ?? [];
  final counts = {'pending': 0, 'processing': 0, 'shipped': 0, 'delivered': 0, 'cancelled': 0};
  for (var order in orders) {
    if (counts.containsKey(order.status)) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
  }
  return counts;
});

final orderFilterProvider = StateProvider<String>((ref) => 'all');

final filteredOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  final filter = ref.watch(orderFilterProvider);
  final allOrders = ref.watch(orderProvider).value ?? [];
  if (filter == 'all') return allOrders;
  return allOrders.where((order) => order.status == filter).toList();
});

final orderDetailsProvider = FutureProvider.family.autoDispose<Order?, String>((ref, orderId) async {
  final order = await ref.watch(orderServiceProvider).getOrderById(orderId);
  ref.onDispose(() {});
  return order;
});
