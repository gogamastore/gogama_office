// lib/providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';

// Menyediakan instance OrderService
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// Provider untuk mengambil SEMUA pesanan sekali saja. Ini adalah sumber data utama.
final allOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getAllOrders();
});

// DIperbaiki: Provider untuk menghitung jumlah pesanan berdasarkan status.
// Dibuat sebagai FutureProvider agar bisa menangani state loading/error.
final orderStatusCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  // Mengambil data order dari allOrdersProvider
  final orders = await ref.watch(allOrdersProvider.future);
  
  final Map<String, int> counts = {
    'pending': 0,
    'processing': 0,
    'shipped': 0,
    'delivered': 0,
    'cancelled': 0,
  };

  for (var order in orders) {
    if (counts.containsKey(order.status)) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
  }
  return counts;
});

// Diperbaiki: State untuk menyimpan filter yang sedang aktif, menambahkan ')' yang hilang
final orderFilterProvider = StateProvider<String>((ref) => 'pending');

// Provider UTAMA untuk UI. Dia mengambil semua pesanan, lalu memfilternya di aplikasi.
final filteredOrdersProvider = Provider.autoDispose.family<List<Order>, String>((ref, statusFilter) {
    final allOrdersAsyncValue = ref.watch(allOrdersProvider);

    return allOrdersAsyncValue.when(
        data: (orders) {
            if (statusFilter == 'all') {
                return orders;
            }
            return orders.where((order) => order.status == statusFilter).toList();
        },
        loading: () => [],
        error: (error, stack) {
            print('Error pada filteredOrdersProvider: $error');
            return [];
        },
    );
});

// Provider untuk detail pesanan (tidak berubah)
final orderDetailsProvider = FutureProvider.family.autoDispose<Order?, String>((ref, orderId) async {
  return ref.watch(orderServiceProvider).getOrderById(orderId);
});
