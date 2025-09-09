import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/dashboard_data.dart';
import '../models/sales_data.dart';
import '../models/order.dart';

class DashboardService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<DashboardData> getDashboardData() async {
    // Tanggal untuk filter pesanan (30 hari terakhir)
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    // Mengambil data pesanan yang sudah selesai (Delivered)
    final deliveredOrdersQuery = _db.collection('orders').where('status', isEqualTo: 'Delivered');
    final deliveredOrdersSnapshot = await deliveredOrdersQuery.get();

    // Menghitung total pendapatan dan penjualan
    double totalRevenue = 0;
    for (var doc in deliveredOrdersSnapshot.docs) {
      final data = doc.data();
      final totalString = (data['total'] as String).replaceAll(RegExp(r'[^0-9]'), '');
      totalRevenue += double.tryParse(totalString) ?? 0;
    }
    final int totalSales = deliveredOrdersSnapshot.docs.length;

    // Mengambil jumlah pelanggan baru (reseller)
    final newCustomersSnapshot = await _db.collection('users').where('role', isEqualTo: 'reseller').get();
    final int newCustomers = newCustomersSnapshot.docs.length;

    // Mengambil total produk dan produk stok menipis
    final productsSnapshot = await _db.collection('products').get();
    final int totalProducts = productsSnapshot.docs.length;

    int lowStockProducts = 0;
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      if ((data['stock'] as num) <= 5) {
        lowStockProducts++;
      }
    }

    // Mengambil 5 pesanan terbaru
    final recentOrdersSnapshot = await _db.collection('orders')
        .orderBy('date', descending: true)
        .limit(5)
        .get();
    final List<Order> recentOrders = recentOrdersSnapshot.docs
        .map((doc) => Order.fromFirestore(doc as firestore.DocumentSnapshot))
        .toList();

    return DashboardData(
      totalRevenue: totalRevenue.round(),
      totalSales: totalSales,
      newCustomers: newCustomers,
      totalProducts: totalProducts,
      lowStockProducts: lowStockProducts,
      recentOrders: recentOrders,
    );
  }

  Future<List<SalesData>> getSalesAnalytics() async {
    // Untuk menyederhanakan, kita akan membuat data mock yang mencerminkan
    // logika dari versi React Native Anda
    return [
      SalesData(label: 'Jul', value: 2500000),
      SalesData(label: 'Agt', value: 12500000),
      SalesData(label: 'Sep', value: 5000000),
      SalesData(label: 'Okt', value: 7500000),
      SalesData(label: 'Nov', value: 9000000),
      SalesData(label: 'Des', value: 11000000),
    ];
  }
}