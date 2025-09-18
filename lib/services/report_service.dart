import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/order.dart' as app_order;
import '../models/product_sales_data.dart';
import '../models/product_sales_history.dart';
import '../models/receivable_data.dart';
import '../models/purchase.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- FUNGSI LAPORAN UTANG DAGANG ---
  Future<List<Purchase>> generatePayableReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    final query = _db
        .collection('purchase_transactions')
        .where('paymentMethod', whereIn: ['credit', 'Credit'])
        .where('purchaseDate', isGreaterThanOrEqualTo: inclusiveStartDate)
        .where('purchaseDate', isLessThan: exclusiveEndDate);

    final snapshot = await query.get();

    final List<Purchase> payableList = snapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['paymentStatus'] != 'paid';
        })
        .map((doc) => Purchase.fromMap(doc.id, doc.data()))
        .toList();

    payableList.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

    return payableList;
  }

  // --- FUNGSI LAPORAN PIUTANG ---
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchOrdersByPaymentStatus(
    String paymentStatus,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db
        .collection('orders')
        .where('paymentStatus', isEqualTo: paymentStatus)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .get()
        .then((snapshot) => snapshot.docs);
  }

  Future<List<ReceivableData>> generateReceivableReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    const List<String> paymentStatusVariations = ['unpaid', 'Unpaid'];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> paymentFutures = 
        paymentStatusVariations.map((status) => _fetchOrdersByPaymentStatus(status, inclusiveStartDate, exclusiveEndDate)).toList();

    final List<List<QueryDocumentSnapshot>> paymentResults = await Future.wait(paymentFutures);
    final List<QueryDocumentSnapshot> allUnpaidDocs = paymentResults.expand((docs) => docs).toList();

    final List<ReceivableData> receivableList = [];
    const List<String> validOrderStates = ['processing', 'shipped', 'delivered'];
    const List<String> invalidOrderStates = ['canceled'];

    for (var doc in allUnpaidDocs) {
      final order = app_order.Order.fromFirestore(doc);
      final orderStatusLower = order.status.toLowerCase();

      if (validOrderStates.contains(orderStatusLower) && !invalidOrderStates.contains(orderStatusLower)) {
        double total = 0.0;
        try {
          String cleanTotal = order.total.replaceAll(RegExp(r'[^0-9]'), '');
          total = double.tryParse(cleanTotal) ?? 0.0;
        } catch (e) {
          // Error handling
        }

        receivableList.add(
          ReceivableData(
            orderId: order.id,
            customerName: order.customer,
            orderDate: order.date.toDate(),
            orderStatus: order.status,
            totalReceivable: total,
          ),
        );
      }
    }

    receivableList.sort((a, b) => a.orderDate.compareTo(b.orderDate));
    return receivableList;
  }
  
  // --- FUNGSI PENJUALAN PRODUK ---
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchOrdersByStatus(
    String status,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .get()
        .then((snapshot) => snapshot.docs);
  }

  Future<List<ProductSalesData>> generateProductSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    const List<String> statusVariations = ['processing', 'Processing', 'shipped', 'Shipped', 'delivered', 'Delivered'];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> futures = 
        statusVariations.map((status) => _fetchOrdersByStatus(status, inclusiveStartDate, exclusiveEndDate)).toList();

    final List<List<QueryDocumentSnapshot>> results = await Future.wait(futures);
    final List<QueryDocumentSnapshot> allOrderDocs = results.expand((docs) => docs).toList();

    final productsSnapshot = await _db.collection('products').get();
    final productsMap = {for (var doc in productsSnapshot.docs) doc.id: Product.fromFirestore(doc)};

    final salesAggregation = <String, int>{};

    for (var orderDoc in allOrderDocs) {
      final orderData = app_order.Order.fromFirestore(orderDoc);
      for (var productInOrder in orderData.products) {
        salesAggregation.update(
          productInOrder.productId,
          (value) => value + productInOrder.quantity, // <-- DIPERBAIKI
          ifAbsent: () => productInOrder.quantity,
        );
      }
    }

    final List<ProductSalesData> reportData = [];
    salesAggregation.forEach((productId, totalSold) {
      final product = productsMap[productId];
      if (product != null) {
        reportData.add(ProductSalesData(product: product, totalSold: totalSold));
      }
    });

    reportData.sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return reportData;
  }

  Future<List<ProductSalesHistory>> getProductSalesHistory({
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));

    const List<String> statusVariations = ['processing', 'Processing', 'shipped', 'Shipped', 'delivered', 'Delivered'];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> futures = 
        statusVariations.map((status) => _fetchOrdersByStatus(status, inclusiveStartDate, exclusiveEndDate)).toList();

    final List<List<QueryDocumentSnapshot>> results = await Future.wait(futures);
    final List<QueryDocumentSnapshot> allOrderDocs = results.expand((docs) => docs).toList();

    final List<ProductSalesHistory> history = [];

    for (var orderDoc in allOrderDocs) {
      final orderData = app_order.Order.fromFirestore(orderDoc);
      
      for (var item in orderData.products) {
        if (item.productId == productId) {
          history.add(
            ProductSalesHistory(
              orderId: orderDoc.id,
              customerName: orderData.customer,
              orderDate: orderData.date.toDate(),
              quantity: item.quantity,
            ),
          );
        }
      }
    }
    
    history.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return history;
  }
}
