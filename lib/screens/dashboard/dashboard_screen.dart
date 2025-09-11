// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dashboard_data.dart';
import '../../models/sales_data.dart';
import '../../models/order.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);
    final salesDataAsync = ref.watch(salesAnalyticsProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(dashboardDataProvider);
          ref.refresh(salesAnalyticsProvider);
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(user?.email?.split('@')[0] ?? 'User', ref),
                const SizedBox(height: 24),

                // Stats Cards
                dashboardDataAsync.when(
                  data: (data) => _buildStatsContainer(data),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),

                // Sales Overview Chart
                salesDataAsync.when(
                  data: (salesData) => _buildSalesChart(salesData),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),

                // Recent Orders
                dashboardDataAsync.when(
                  data: (data) => _buildRecentOrders(data.recentOrders),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 24),

                // Success Message
                _buildSuccessMessage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
      children: [
        // FIX: Wrap the column in an Expanded widget to prevent horizontal overflow.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Grosir Gallery Makassar', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 4),
              Text(
                userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                overflow: TextOverflow.ellipsis, // Prevent long usernames from overflowing
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF5DADE2)),
          onPressed: () => ref.read(authServiceProvider).signOut(),
        ),
      ],
    );
  }

  Widget _buildStatsContainer(DashboardData data) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF5DADE2),
              value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(data.totalRevenue),
              label: 'Total Revenue',
              subtext: 'Total dari pesanan yang selesai',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFF27AE60),
              value: '+${data.totalSales}',
              label: 'Sales',
              subtext: 'Jumlah pesanan yang selesai',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFFE74C3C),
              value: '+${data.newCustomers}',
              label: 'New Customers',
              subtext: 'Total reseller terdaftar',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFFF39C12),
              value: '${data.totalProducts}',
              label: 'Products in Stock',
              subtext: '${data.lowStockProducts} produk stok menipis',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label, required String subtext}) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
              const SizedBox(height: 4),
              Text(subtext, style: const TextStyle(fontSize: 11, color: Color(0xFF7F8C8D))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<SalesData> salesData) {
    final maxValue = salesData.isNotEmpty
        ? salesData.map((d) => d.value).reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), spreadRadius: 1, blurRadius: 2)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          const Text('Data Penjualan selama 6 Bulan Terakhir.', style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            // FIX: Wrap the Row in a SingleChildScrollView to make the chart scrollable horizontally.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: salesData.map((item) {
                  // FIX: Reduce the bar height multiplier to prevent vertical overflow.
                  final height = maxValue > 0 ? (item.value / maxValue) * 100 : 10.0;
                  return _buildChartColumn(item.label, height, item.value);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartColumn(String label, double height, int value) {
    final formattedValue = NumberFormat.compact(locale: 'id_ID').format(value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Increased padding for better spacing
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Text(formattedValue, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5DADE2))),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: height,
            decoration: BoxDecoration(
              color: value > 0 ? const Color(0xFF5DADE2) : const Color(0xFFE0E6ED),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<Order> orders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), spreadRadius: 1, blurRadius: 2)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          const Text('A list of the most recent orders.', style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
            ],
          ),
          const Divider(color: Color(0xFFE0E6ED)),
          ...orders.map((order) => _buildOrderRow(order)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50)), overflow: TextOverflow.ellipsis,),
                Text(DateFormat('dd/MM/yy HH:mm').format(order.date.toDate()), style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(order.total, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusColor(order.status)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return const Color(0xFF27AE60);
      case 'shipped': return const Color(0xFF3498DB);
      case 'processing': return const Color(0xFFF39C12);
      case 'pending': return const Color(0xFFE74C3C);
      case 'cancelled': return const Color(0xFF95A5A6);
      default: return const Color(0xFF7F8C8D);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return 'Selesai';
      case 'shipped': return 'Dikirim';
      case 'processing': return 'Diproses';
      case 'pending': return 'Menunggu';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }

  Widget _buildSuccessMessage() {
    return Container(
      // The margin was causing issues on smaller screens, let's remove horizontal margin from here
      // and let the parent padding handle it.
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), spreadRadius: 1, blurRadius: 2)],
      ),
      // FIX: Restructure the Row to be more flexible.
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF27AE60)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Terbaru!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27AE60),
                  ),
                ),
                Text(
                  'Disinkronkan dari Firestore',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                  overflow: TextOverflow.ellipsis, // Add overflow handling
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
