
import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk menampung data laporan penjualan secara keseluruhan
class SalesReportData {
  final double totalRevenue;
  final double totalCogs;
  final List<SalesReportOrder> orders;

  SalesReportData({
    required this.totalRevenue,
    required this.totalCogs,
    required this.orders,
  });

  // Laba kotor dihitung dari selisih pendapatan dan HPP
  double get grossProfit => totalRevenue - totalCogs;
}

// Model yang merepresentasikan satu pesanan dalam laporan penjualan
class SalesReportOrder {
  final String orderId;
  final Timestamp orderDate;
  final String customerName;
  final String? customerId;
  final List<SalesReportItem> items;
  final double totalRevenue;
  final double totalCogs;

  SalesReportOrder({
    required this.orderId,
    required this.orderDate,
    required this.customerName,
    this.customerId,
    required this.items,
    required this.totalRevenue,
    required this.totalCogs,
  });

  // Laba kotor per pesanan
  double get grossProfit => totalRevenue - totalCogs;
}

// Model yang merepresentasikan satu item produk dalam pesanan di laporan
class SalesReportItem {
  final String productId;
  final String productName;
  final int quantity;
  final double salePrice; // Harga jual per unit
  final double purchasePrice; // Harga beli (pokok) per unit

  SalesReportItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
  });

  // Subtotal penjualan untuk item ini (Harga Jual * Kuantitas)
  double get totalSale => salePrice * quantity;
  // Subtotal HPP untuk item ini (Harga Beli * Kuantitas)
  double get totalCogs => purchasePrice * quantity;
}
