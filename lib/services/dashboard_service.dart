import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/dashboard_data.dart';
import '../models/order.dart';
import '../models/sales_data.dart';

class DashboardService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<DashboardData> getDashboardData() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

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

    return DashboardData(
      totalRevenue: totalRevenueToday.round(),
      totalSales: totalSalesToday,
      newCustomers: newCustomers,
      totalProducts: totalProducts,
      lowStockProducts: lowStockProducts,
      recentOrders: recentOrders,
    );
  }

  // --- FUNGSI INI DIUBAH UNTUK MENGAMBIL DATA 1 BULAN TERAKHIR ---
  Future<List<SalesData>> getSalesAnalytics() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    Map<int, int> dailySales = {};

    // 1. Inisialisasi 30 hari terakhir
    for (int i = 0; i < 30; i++) {
      final day = thirtyDaysAgo.add(Duration(days: i));
      dailySales[day.day] = 0;
    }

    // 2. Query pesanan dalam 30 hari terakhir
    final querySnapshot = await _db
        .collection('orders')
        .where('status', whereIn: ['delivered', 'shipped', 'processing'])
        .where('date',
            isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

    // 3. Proses data penjualan harian
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final orderDate = (data['date'] as firestore.Timestamp).toDate();
      final dayKey = orderDate.day;

      final total = data['total'];
      int orderTotal = 0;
      if (total is num) {
        orderTotal = total.toInt();
      } else if (total is String) {
        orderTotal = int.tryParse(total.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      if (dailySales.containsKey(dayKey)) {
        dailySales[dayKey] = dailySales[dayKey]! + orderTotal;
      }
    }

    // 4. Ubah ke format List<SalesData>
    return dailySales.entries
        .map((entry) =>
            SalesData(label: entry.key.toString(), value: entry.value))
        .toList();
  }
}
