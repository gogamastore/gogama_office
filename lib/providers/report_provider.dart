import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reports/customer_report_model.dart';
import '../models/reports/order_model.dart';
import 'customer_data_provider.dart'; // <<< DIPERBARUI: Impor provider pelanggan yang baru

// 1. Provider untuk mengambil semua data pesanan mentah (tidak berubah)
final allOrdersProvider = StreamProvider<List<SimpleOrder>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('orders')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => SimpleOrder.fromFirestore(doc)).toList());
});

// 2. Provider state untuk rentang tanggal (tidak berubah)
final dateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// 3. Provider utama yang memproses data (DIPERBARUI)
final customerReportProvider = Provider<AsyncValue<List<CustomerReport>>>((ref) {
  // Tonton data pelanggan dan data pesanan
  final customersMapAsync = ref.watch(customerMapProvider);
  final ordersAsync = ref.watch(allOrdersProvider);
  final dateRange = ref.watch(dateRangeProvider);

  // Tangani state loading/error dari beberapa sumber
  if (customersMapAsync is AsyncLoading || ordersAsync is AsyncLoading) {
    return const AsyncLoading();
  }
  if (customersMapAsync is AsyncError) {
    return AsyncError(customersMapAsync.error!, customersMapAsync.stackTrace!);
  }
  if (ordersAsync is AsyncError) {
    return AsyncError(ordersAsync.error!, ordersAsync.stackTrace!);
  }

  // Jika semua data siap, kita lanjutkan
  final customersMap = customersMapAsync.value!;
  final allOrders = ordersAsync.value!;

  // Filter pesanan berdasarkan tanggal (logika tetap sama)
  final filteredOrders = allOrders.where((order) {
    if (dateRange == null) return true;
    return order.date.isAfter(dateRange.start) &&
        order.date.isBefore(dateRange.end.add(const Duration(days: 1)));
  }).toList();

  // Proses agregasi data
  final Map<String, CustomerReport> reportMap = {};

  for (var order in filteredOrders) {
    final customerId = order.customerId;

    // Lewati pesanan jika tidak memiliki customerId yang valid
    if (customerId == null || customerId.isEmpty) continue;

    // <<< PERUBAHAN UTAMA DI SINI >>>
    // Dapatkan nama dari map pelanggan. Jika tidak ada, gunakan nama dari pesanan sebagai fallback.
    final customerName = customersMap[customerId] ?? order.customerName;

    if (!reportMap.containsKey(customerId)) {
      reportMap[customerId] = CustomerReport(
        id: customerId,
        name: customerName, // Gunakan nama yang sudah divalidasi
        orders: [],
      );
    }

    // Update data agregat (logika tetap sama)
    final report = reportMap[customerId]!;
    report.transactionCount++;
    report.totalSpent += order.total;

    final status = order.status.toLowerCase();
    final paymentStatus = order.paymentStatus.toLowerCase();
    if (paymentStatus == 'unpaid' && (status == 'shipped' || status == 'delivered')) {
      report.receivables += order.total;
    }

    report.orders.add(order);
  }

  final reportList = reportMap.values.toList();
  reportList.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

  return AsyncData(reportList);
});


// 4. Provider untuk mengambil detail satu pesanan (tidak berubah)
final singleOrderProvider =
    FutureProvider.family<FullOrder?, String>((ref, orderId) async {
  if (orderId.isEmpty) return null;
  try {
    final doc =
        await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return FullOrder.fromFirestore(doc);
    }
    return null;
  } catch (e) {
    return null;
  }
});
