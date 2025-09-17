import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sales_report_data.dart';

@immutable
class SalesReportState {
  final DateTimeRange? selectedDateRange;
  final SalesReportData? reportData;
  final bool isLoading;
  final String? errorMessage;

  const SalesReportState({
    this.selectedDateRange,
    this.reportData,
    this.isLoading = false,
    this.errorMessage,
  });

  SalesReportState copyWith({
    DateTimeRange? selectedDateRange,
    SalesReportData? reportData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SalesReportState(
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      reportData: reportData ?? this.reportData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SalesReportNotifier extends StateNotifier<SalesReportState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SalesReportNotifier() : super(const SalesReportState());

  void setDateRange(DateTimeRange dateRange) {
    state = state.copyWith(selectedDateRange: dateRange);
  }

  // Helper function to fetch details in chunks to avoid the 30-item 'in' query limit.
  Future<Map<String, DocumentSnapshot>> _fetchDetailsInChunks(
      String collection, Set<String> ids) async {
    final details = <String, DocumentSnapshot>{};
    if (ids.isEmpty) {
      return details;
    }

    final idList = ids.toList();
    const chunkSize = 30;

    for (var i = 0; i < idList.length; i += chunkSize) {
      final chunk = idList.sublist(i, i + chunkSize > idList.length ? idList.length : i + chunkSize);
      final snapshot = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in snapshot.docs) {
        details[doc.id] = doc;
      }
    }
    return details;
  }

  Future<void> generateReport() async {
    if (state.selectedDateRange == null) {
      state = state.copyWith(errorMessage: 'Pilih rentang tanggal terlebih dahulu.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final startDate = Timestamp.fromDate(state.selectedDateRange!.start);
      final endDate = Timestamp.fromDate(state.selectedDateRange!.end.add(const Duration(days: 1)));

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .orderBy('date', descending: true)
          .get();

      final relevantDocs = ordersSnapshot.docs.where((doc) {
        final data = doc.data();
        final status = data['status'];
        if (status is! String) return false;
        return ['processing', 'shipped', 'delivered'].contains(status.toLowerCase());
      }).toList();

      if (relevantDocs.isEmpty) {
        state = state.copyWith(reportData: SalesReportData(totalRevenue: 0, totalCogs: 0, orders: []), isLoading: false);
        return;
      }

      // Get all product and customer IDs
      final productIds = relevantDocs.expand((doc) => (doc.data()['products'] as List<dynamic>).map<String>((item) => item['productId'] as String)).toSet();
      
      // THE FIX: Use .whereType<String>() to filter nulls and get the correct Set<String> type.
      final customerIds = relevantDocs.map((doc) => doc.data()['customerId'] as String?).whereType<String>().toSet();

      // Fetch details in chunks
      final productDetails = await _fetchDetailsInChunks('products', productIds);
      final customerDetails = await _fetchDetailsInChunks('user', customerIds);

      double totalRevenue = 0;
      double totalCogs = 0;
      List<SalesReportOrder> salesOrders = [];

      for (var orderDoc in relevantDocs) {
        try {
          final orderData = orderDoc.data();
          final customerId = orderData['customerId'] as String?;
          final customerName = (customerDetails[customerId]?.data() as Map<String, dynamic>?)?['name'] as String? ?? orderData['customer'] as String? ?? 'Pelanggan Langsung';

          List<SalesReportItem> items = [];
          double orderRevenue = 0;
          double orderCogs = 0;

          for (var item in (orderData['products'] as List<dynamic>)) {
              final productId = item['productId'] as String;
              final productDoc = productDetails[productId];
              if (productDoc != null && productDoc.exists) {
                  final productData = productDoc.data() as Map<String, dynamic>;
                  final salePrice = (item['price'] as num).toDouble();
                  final quantity = (item['quantity'] as num).toInt();
                  final purchasePrice = (productData['purchasePrice'] as num?)?.toDouble() ?? 0.0;
                  items.add(SalesReportItem(productId: productId, productName: productData['name'] ?? 'N/A', quantity: quantity, salePrice: salePrice, purchasePrice: purchasePrice));
                  orderRevenue += salePrice * quantity;
                  orderCogs += purchasePrice * quantity;
              }
          }
          
          salesOrders.add(SalesReportOrder(orderId: orderDoc.id, orderDate: orderData['date'] as Timestamp, customerName: customerName, customerId: customerId, status: orderData['status'] as String, items: items, totalRevenue: orderRevenue, totalCogs: orderCogs));
          totalRevenue += orderRevenue;
          totalCogs += orderCogs;

        } catch (e, stackTrace) {
          developer.log(
            'Skipping order due to processing error. Order ID: ${orderDoc.id}',
            name: 'sales_report_provider',
            level: 900, 
            error: e,
            stackTrace: stackTrace,
          );
          continue;
        }
      }

      state = state.copyWith(reportData: SalesReportData(totalRevenue: totalRevenue, totalCogs: totalCogs, orders: salesOrders), isLoading: false, errorMessage: null);

    } catch (e, stackTrace) {
       developer.log(
        'Critical error in generateReport',
        name: 'sales_report_provider',
        level: 1000,
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: "Terjadi error kritis yang tidak terduga. Silakan coba lagi.", isLoading: false);
    }
  }
}

final salesReportProvider = StateNotifierProvider<SalesReportNotifier, SalesReportState>((ref) => SalesReportNotifier());
