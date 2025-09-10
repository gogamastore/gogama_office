// lib/providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/order_product.dart';
import '../services/order_service.dart';

// Menyediakan instance OrderService
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// Notifier untuk mengelola state pesanan (baca & tulis)
class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderService _orderService;

  OrderNotifier(this._orderService) : super(const AsyncValue.loading()) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await _orderService.getAllOrders();
      state = AsyncValue.data(orders);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    await _fetchOrders();
  }

  Future<bool> updateOrder(String orderId, List<OrderProduct> products, double shippingFee, double newTotal) async {
    try {
      await _orderService.updateOrderDetails(orderId, products, shippingFee, newTotal);
      await refresh();
      return true;
    } catch (e) {
      print('Gagal memperbarui pesanan: $e');
      return false;
    }
  }
}

// StateNotifierProvider yang baru untuk mengelola state pesanan
final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(ref.watch(orderServiceProvider));
});

// PERBAIKAN: Provider yang lebih sederhana untuk menghitung jumlah pesanan.
// Provider ini secara otomatis akan masuk ke state loading/error jika orderProvider juga loading/error.
final orderStatusCountsProvider = Provider.autoDispose<Map<String, int>>((ref) {
  // Ambil data pesanan. Jika loading/error, .value akan null, dan kita kembalikan list kosong.
  final orders = ref.watch(orderProvider).value ?? [];

  final counts = {'pending': 0, 'processing': 0, 'shipped': 0, 'delivered': 0, 'cancelled': 0};
  for (var order in orders) {
    if (counts.containsKey(order.status)) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
  }
  return counts;
});

// State untuk menyimpan filter yang sedang aktif
final orderFilterProvider = StateProvider<String>((ref) => 'pending');

// Provider untuk UI. Dia mengambil data dari orderProvider, lalu memfilternya.
final filteredOrdersProvider = Provider.autoDispose.family<List<Order>, String>((ref, statusFilter) {
  // .value akan null jika loading/error, jadi kita beri nilai default list kosong
  final allOrders = ref.watch(orderProvider).value ?? [];
  
  if (statusFilter == 'all') return allOrders;
  return allOrders.where((order) => order.status == statusFilter).toList();
});

// Provider untuk detail pesanan.
final orderDetailsProvider = FutureProvider.family.autoDispose<Order?, String>((ref, orderId) async {
  final ordersAsync = ref.watch(orderProvider);
  // Coba ambil dari state yang sudah ada untuk respons instan
  if (ordersAsync is AsyncData<List<Order>>) {
    final orders = ordersAsync.value;
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      // Jika tidak ditemukan, fallback ke fetch dari service
    }
  }
  // Fallback: fetch langsung jika data belum ada atau sedang loading
  return ref.watch(orderServiceProvider).getOrderById(orderId);
});
