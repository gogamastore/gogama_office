import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sales_report_data.dart';

// 1. State class
@immutable
class SalesReportState {
  final bool isLoading;
  final String? errorMessage;
  final SalesReportData? reportData;
  final DateTimeRange? selectedDateRange;

  const SalesReportState({
    this.isLoading = false,
    this.errorMessage,
    this.reportData,
    this.selectedDateRange,
  });

  SalesReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    SalesReportData? reportData,
    DateTimeRange? selectedDateRange,
  }) {
    return SalesReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      reportData: reportData ?? this.reportData,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
    );
  }
}

// 2. StateNotifier class
class SalesReportNotifier extends StateNotifier<SalesReportState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SalesReportNotifier() : super(const SalesReportState());

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(selectedDateRange: range, reportData: null, errorMessage: null);
  }

  Future<void> generateReport() async {
    if (state.selectedDateRange == null) {
      state = state.copyWith(errorMessage: "Silakan pilih rentang tanggal terlebih dahulu.");
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, reportData: null);

    try {
      final productsSnapshot = await _firestore.collection('products').get();
      final productPurchasePrices = { for (var doc in productsSnapshot.docs) doc.id: (doc.data()['purchasePrice'] ?? 0).toDouble() };
      final productNames = { for (var doc in productsSnapshot.docs) doc.id: (doc.data()['name'] ?? 'Unknown Product').toString() };

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('date', isGreaterThanOrEqualTo: state.selectedDateRange!.start)
          .where('date', isLessThanOrEqualTo: state.selectedDateRange!.end.add(const Duration(days: 1)))
          .where('status', whereIn: ['Processing', 'Shipped', 'Delivered']).get();

      final List<SalesReportOrder> reportOrders = [];
      double grandTotalRevenue = 0;
      double grandTotalCogs = 0;

      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final List<dynamic> productsInOrder = orderData['products'] ?? [];
        double orderTotalRevenue = 0;
        double orderTotalCogs = 0;
        final List<SalesReportItem> reportItems = [];

        for (var productItem in productsInOrder) {
          final String productId = productItem['productId'];
          final int quantity = productItem['quantity'];
          final double salePrice = (productItem['price'] ?? 0).toDouble();
          final double purchasePrice = productPurchasePrices[productId] ?? 0;
          final String productName = productNames[productId] ?? 'Unknown Product';

          final itemRevenue = salePrice * quantity;
          final itemCogs = purchasePrice * quantity;
          orderTotalRevenue += itemRevenue;
          orderTotalCogs += itemCogs;

          reportItems.add(
            SalesReportItem(
              productId: productId,
              productName: productName,
              quantity: quantity,
              salePrice: salePrice,
              purchasePrice: purchasePrice,
            ),
          );
        }

        reportOrders.add(
          SalesReportOrder(
            orderId: orderDoc.id,
            orderDate: orderData['date'],
            customerName: orderData['customer'] ?? 'N/A',
            customerId: orderData['customerId'],
            items: reportItems,
            totalRevenue: orderTotalRevenue,
            totalCogs: orderTotalCogs,
          ),
        );

        grandTotalRevenue += orderTotalRevenue;
        grandTotalCogs += orderTotalCogs;
      }

      // Mengurutkan pesanan dari yang terbaru ke yang terlama
      reportOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      final newReportData = SalesReportData(
        totalRevenue: grandTotalRevenue,
        totalCogs: grandTotalCogs,
        orders: reportOrders,
      );
      
      state = state.copyWith(isLoading: false, reportData: newReportData);

    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Terjadi kesalahan: $e");
    } 
  }
}

// 3. Provider
final salesReportProvider = StateNotifierProvider<SalesReportNotifier, SalesReportState>((ref) {
  return SalesReportNotifier();
});