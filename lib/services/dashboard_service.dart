
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/dashboard_data.dart';
import '../models/order.dart';
import '../models/sales_data.dart';

class DashboardService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<DashboardData> getDashboardData() async {
    // --- PERBAIKAN: Tentukan rentang waktu untuk "Hari Ini" ---
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // --- Query untuk Total Revenue & Sales HARI INI ---
    final todaysOrdersQuery = _db
        .collection('orders')
        .where('status', whereIn: ['Processing', 'Shipped', 'Delivered'])
        .where('date', isGreaterThanOrEqualTo: startOfToday)
        .where('date', isLessThanOrEqualTo: endOfToday);
    final todaysOrdersSnapshot = await todaysOrdersQuery.get();

    double totalRevenueToday = 0;
    for (var doc in todaysOrdersSnapshot.docs) {
      final data = doc.data();
      final dynamic totalValue = data['total'];
      double orderTotal = 0;

      if (totalValue is String) {
        final totalString = totalValue.replaceAll(RegExp(r'[^0-9]'), '');
        orderTotal = double.tryParse(totalString) ?? 0.0;
      } else if (totalValue is num) {
        orderTotal = totalValue.toDouble();
      }
      totalRevenueToday += orderTotal;
    }
    final int totalSalesToday = todaysOrdersSnapshot.docs.length;

    // --- Query untuk data lainnya (tetap dalam rentang 30 hari atau total) ---
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    final newCustomersQuery = _db
        .collection('user')
        .where('role', isEqualTo: 'reseller')
        .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo);
    final newCustomersSnapshot = await newCustomersQuery.get();
    final int newCustomers = newCustomersSnapshot.docs.length;

    final productsSnapshot = await _db.collection('products').get();
    final int totalProducts = productsSnapshot.docs.length;

    int lowStockProducts = 0;
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      if ((data['stock'] as num? ?? 0) <= 5) {
        lowStockProducts++;
      }
    }

    final recentOrdersSnapshot = await _db
        .collection('orders')
        .orderBy('date', descending: true)
        .limit(5)
        .get();
    final List<Order> recentOrders = recentOrdersSnapshot.docs
        .map((doc) => Order.fromFirestore(doc as firestore.DocumentSnapshot))
        .toList();

    // --- Kembalikan data dengan nilai HARI INI untuk revenue dan sales ---
    return DashboardData(
      totalRevenue: totalRevenueToday.round(),
      totalSales: totalSalesToday,
      newCustomers: newCustomers, // Tetap 30 hari terakhir
      totalProducts: totalProducts, // Tetap total
      lowStockProducts: lowStockProducts, // Tetap total
      recentOrders: recentOrders, // Tetap 5 terakhir
    );
  }

  Future<List<SalesData>> getSalesAnalytics() async {
    // Data mock untuk analitik penjualan (tidak berubah)
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
