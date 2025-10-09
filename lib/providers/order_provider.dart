import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/order_item.dart';
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

  Future<bool> createOrder(Order order) async {
    try {
      await _orderService.createOrder(order);
      await refresh();
      return true;
    } catch (e, s) {
      log('Gagal membuat pesanan', error: e, stackTrace: s);
      return false;
    }
  }

  // --- BLOK CATCH DIPERBARUI UNTUK DIAGNOSTIK FINAL ---
  Future<bool> createCustomerOrder(Map<String, dynamic> orderData) async {
    try {
      await _orderService.createOrderFromMap(orderData);
      await refresh();
      return true;
    } on FirebaseException catch (e, s) {
      // Tangkap error spesifik dari Firebase
      log(
        'Error Firebase saat membuat pesanan:',
        name: 'FirebaseError',
        level: 1000, // SEVERE
        error: 'Code: ${e.code}\nMessage: ${e.message}',
        stackTrace: s,
      );
      return false;
    } catch (e, s) {
      // Tangkap error lainnya untuk melihat TIPE error yang sebenarnya
      log(
        'Error umum saat membuat pesanan pelanggan. TIPE ERROR: ${e.runtimeType.toString()}',
        name: 'GeneralError',
        level: 1000,
        error: e, // Mencetak objek error itu sendiri
        stackTrace: s,
      );
      return false;
    }
  }
  // --- AKHIR BLOK DIAGNOSTIK ---

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

final orderProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(ref.watch(orderServiceProvider));
});

final orderStatusCountsProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final orders = ref.watch(orderProvider).value ?? [];
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

final orderFilterProvider = StateProvider<String>((ref) => 'pending');

final orderSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  final statusFilter = ref.watch(orderFilterProvider);
  final searchQuery = ref.watch(orderSearchQueryProvider).toLowerCase();
  final allOrders = ref.watch(orderProvider).value ?? [];

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


final ordersByStatusProvider =
    Provider.family.autoDispose<AsyncValue<List<Order>>, String>((ref, status) {
  final allOrdersAsync = ref.watch(orderProvider);
  return allOrdersAsync.when(
    data: (orders) =>
        AsyncValue.data(orders.where((o) => o.status == status).toList()),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final orderDetailsProvider =
    FutureProvider.family.autoDispose<Order?, String>((ref, orderId) async {
  final order = await ref.watch(orderServiceProvider).getOrderById(orderId);
  ref.onDispose(() {});
  return order;
});
