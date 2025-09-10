import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/dashboard_data.dart';
import '../models/order.dart';
import '../models/sales_data.dart';

class DashboardService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<DashboardData> getDashboardData() async {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    // PERBAIKAN: Mengambil pesanan dengan status 'Processing', 'Shipped', atau 'Delivered'
    final relevantOrdersQuery = _db
        .collection('orders')
        .where('status', whereIn: ['Processing', 'Shipped', 'Delivered'])
        .where('date', isGreaterThanOrEqualTo: oneMonthAgo);
    final relevantOrdersSnapshot = await relevantOrdersQuery.get();

    double totalRevenue = 0;
    for (var doc in relevantOrdersSnapshot.docs) {
      final data = doc.data();
      final dynamic totalValue = data['total'];
      double orderTotal = 0;

      if (totalValue is String) {
        final totalString = totalValue.replaceAll(RegExp(r'[^0-9]'), '');
        orderTotal = double.tryParse(totalString) ?? 0.0;
      } else if (totalValue is num) {
        orderTotal = totalValue.toDouble();
      }
      totalRevenue += orderTotal;
    }
    final int totalSales = relevantOrdersSnapshot.docs.length;

    // PERBAIKAN: Menggunakan nama koleksi 'user' (bukan 'users')
    final newCustomersQuery = _db
        .collection('user') // Sesuai struktur Anda
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
    // Data mock untuk analitik penjualan
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
