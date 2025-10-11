import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/myorder.dart';
// import '../models/order.dart' as old_order; // DIHAPUS: Impor tidak digunakan
import '../models/order_item.dart';
import '../services/order_service.dart';

final myOrderServiceProvider = Provider<OrderService>((ref) => OrderService());

class MyOrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderService _orderService;

  MyOrderNotifier(this._orderService) : super(const AsyncValue.loading()) {
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final oldOrders = await _orderService.getAllOrders();
      final newOrders = oldOrders.map((o) => Order.fromOldOrder(o)).toList();
      if (mounted) state = AsyncValue.data(newOrders);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    await _fetchOrders();
  }

  Future<bool> createOrder(Order order) async {
    try {
      await _orderService.createOrder(order.toOldOrder());
      await refresh();
      return true;
    } catch (e, s) {
      log('Gagal membuat pesanan', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> createCustomerOrder(Map<String, dynamic> orderData) async {
    try {
      await _orderService.createOrderFromMap(orderData);
      await refresh();
      return true;
    } on FirebaseException catch (e, s) {
      log(
        'Error Firebase saat membuat pesanan:',
        name: 'FirebaseError',
        level: 1000,
        error: 'Code: ${e.code}\nMessage: ${e.message}',
        stackTrace: s,
      );
      return false;
    } catch (e, s) {
      log(
        'Error umum saat membuat pesanan pelanggan. TIPE ERROR: ${e.runtimeType.toString()}',
        name: 'GeneralError',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<bool> updateOrder(String orderId, List<OrderItem> products,
      double shippingFee, double newSubtotal, double newTotal, {String? validatorName}) async {
    try {
      await _orderService.updateOrderDetails(
          orderId, products, shippingFee, newSubtotal, newTotal, validatorName: validatorName);
      await refresh();
      return true;
    } catch (e, s) {
      log('Gagal memperbarui pesanan', error: e, stackTrace: s);
      return false;
    }
  }
}

final myOrderProvider =
    StateNotifierProvider<MyOrderNotifier, AsyncValue<List<Order>>>((ref) {
  return MyOrderNotifier(ref.watch(myOrderServiceProvider));
});

final myOrderStatusCountsProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final orders = ref.watch(myOrderProvider).value ?? [];
  final counts = {
    'pending': 0,
    'processing': 0,
    'shipped': 0,
    'delivered': 0,
    'cancelled': 0
  };
  for (var order in orders) {
    if (counts.containsKey(order.status)) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
  }
  return counts;
});

final myOrderFilterProvider = StateProvider<String>((ref) => 'processing');

final myOrderSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredMyOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  final statusFilter = ref.watch(myOrderFilterProvider);
  final searchQuery = ref.watch(myOrderSearchQueryProvider).toLowerCase();
  final allOrders = ref.watch(myOrderProvider).value ?? [];

  final ordersFilteredByStatus = allOrders
      .where((order) => order.status.toLowerCase() == statusFilter.toLowerCase())
      .toList();

  if (searchQuery.isEmpty) {
    return ordersFilteredByStatus;
  }

  return ordersFilteredByStatus.where((order) {
    final customerNameMatch = order.customer.toLowerCase().contains(searchQuery);
    final orderIdMatch = order.id.toLowerCase().contains(searchQuery);
    final skuMatch = order.products.any((product) {
      final sku = product.sku;
      return sku != null && sku.toLowerCase().contains(searchQuery);
    });

    return customerNameMatch || orderIdMatch || skuMatch;
  }).toList();
});

final myOrdersByStatusProvider =
    Provider.family.autoDispose<AsyncValue<List<Order>>, String>((ref, status) {
  final allOrdersAsync = ref.watch(myOrderProvider);
  return allOrdersAsync.when(
    data: (orders) =>
        AsyncValue.data(orders.where((o) => o.status == status).toList()),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final myOrderDetailsProvider =
    FutureProvider.family.autoDispose<Order?, String>((ref, orderId) async {
  final oldOrder = await ref.watch(myOrderServiceProvider).getOrderById(orderId);
  if (oldOrder == null) return null;
  return Order.fromOldOrder(oldOrder);
});
