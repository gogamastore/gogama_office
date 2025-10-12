import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_item.dart';
import '../models/product.dart';
import '../models/order.dart' as app_order;
import '../models/product_sales_data.dart';
import '../models/product_sales_history.dart';
import '../models/receivable_data.dart';
import '../models/purchase.dart';
import '../models/customer_report.dart'; // Impor model baru

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

   Future<List<ExpenseItem>> getOperationalExpenses({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final querySnapshot = await _db
        .collection('operational_expenses')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return querySnapshot.docs
        .map((doc) => ExpenseItem.fromFirestore(doc))
        .toList();
  }


  // --- FUNGSI GENERATE CUSTOMER REPORT BARU ---
  Future<List<CustomerReport>> generateCustomerReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate =
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));

    // 1. Ambil semua pesanan dalam rentang tanggal
    final querySnapshot = await _db
        .collection('orders')
        .where('date', isGreaterThanOrEqualTo: inclusiveStartDate)
        .where('date', isLessThan: exclusiveEndDate)
        .get();

    final reportMap = <String, CustomerReport>{};

    // 2. Proses setiap pesanan
    for (var doc in querySnapshot.docs) {
      final order = app_order.Order.fromFirestore(doc);

      // Gunakan customerId jika ada, jika tidak, gunakan nama customer sebagai fallback
      final customerId =
          order.customerId.isNotEmpty ? order.customerId : order.customer;

      // Logika untuk menghitung total
      double total = 0.0;
      try {
        // PERBAIKAN: Pertahankan titik desimal
        String cleanTotal = order.total.replaceAll(RegExp(r'[^0-9.]'), '');
        total = double.tryParse(cleanTotal) ?? 0.0;
      } catch (e) {
        total = 0.0;
      }

      // Jika pelanggan belum ada di map, buat entri baru
      reportMap.putIfAbsent(
        customerId,
        () => CustomerReport(
          id: customerId,
          name: order.customer,
          transactionCount: 0,
          totalSpent: 0,
          receivables: 0,
          orders: [],
        ),
      );

      final report = reportMap[customerId]!;

      // Hitung piutang
      final isUnpaid = order.paymentStatus.toLowerCase() == 'unpaid';
      final isValidStatus =
          ['shipped', 'delivered'].contains(order.status.toLowerCase());
      final newReceivables =
          report.receivables + (isUnpaid && isValidStatus ? total : 0);

      // Perbarui laporan dengan data dari pesanan saat ini
      reportMap[customerId] = report.copyWith(
        transactionCount: report.transactionCount + 1,
        totalSpent: report.totalSpent + total,
        receivables: newReceivables,
        orders: [...report.orders, order]
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    }

    // 3. Ubah map menjadi daftar dan urutkan berdasarkan total belanja
    final reportList = reportMap.values.toList();
    reportList.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return reportList;
  }

  Future<void> markOrderAsPaid(String orderId) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);
      await orderRef.update({'paymentStatus': 'paid'});
    } catch (e) {
      throw Exception('Gagal memperbarui status pembayaran: $e');
    }
  }

  Future<app_order.Order> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return app_order.Order.fromFirestore(doc);
      }
      throw Exception('Pesanan tidak ditemukan.');
    } catch (e) {
      throw Exception('Gagal mengambil detail pesanan: $e');
    }
  }

  Future<void> processPurchasePayment({
    required String purchaseId,
    required String paymentMethod,
    String? notes,
  }) async {
    final purchaseRef = _db.collection('purchase_transactions').doc(purchaseId);

    await purchaseRef.update({
      'paymentStatus': 'paid',
      'paymentMethod': paymentMethod,
      'paymentNotes': notes,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Purchase>> generatePayableReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime inclusiveStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate =
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));

    final query = _db
        .collection('purchase_transactions')
        .where('paymentMethod', whereIn: ['credit', 'Credit'])
        .where('date', isGreaterThanOrEqualTo: inclusiveStartDate)
        .where('date', isLessThan: exclusiveEndDate);

    final snapshot = await query.get();

    final List<Purchase> payableList = snapshot.docs
        .map((doc) => Purchase.fromMap(doc.id, doc.data()))
        .toList();

    payableList.sort((a, b) => a.date.compareTo(b.date));

    return payableList;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchOrdersByPaymentStatus(
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
    final DateTime inclusiveStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate =
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));

    const List<String> paymentStatusVariations = ['unpaid', 'Unpaid'];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
        paymentFutures = paymentStatusVariations
            .map((status) => _fetchOrdersByPaymentStatus(
                status, inclusiveStartDate, exclusiveEndDate))
            .toList();

    final List<List<QueryDocumentSnapshot>> paymentResults =
        await Future.wait(paymentFutures);
    final List<QueryDocumentSnapshot> allUnpaidDocs =
        paymentResults.expand((docs) => docs).toList();

    final List<ReceivableData> receivableList = [];
    const List<String> validOrderStates = [
      'processing',
      'shipped',
      'delivered'
    ];
    const List<String> invalidOrderStates = ['canceled'];

    for (var doc in allUnpaidDocs) {
      final order = app_order.Order.fromFirestore(doc);
      final orderStatusLower = order.status.toLowerCase();

      if (validOrderStates.contains(orderStatusLower) &&
          !invalidOrderStates.contains(orderStatusLower)) {
        double total = 0.0;

        try {
          // --- PERBAIKAN: Pertahankan titik desimal ---
          String cleanTotal = order.total.replaceAll(RegExp(r'[^0-9.]'), '');
          total = double.tryParse(cleanTotal) ?? 0.0;
        } catch (e) {
          total = 0.0;
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchOrdersByStatus(
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
    final DateTime inclusiveStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate =
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));

    const List<String> statusVariations = [
      'processing',
      'Processing',
      'shipped',
      'Shipped',
      'delivered',
      'Delivered',
      'completed',
      'Completed'
    ];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
        futures = statusVariations
            .map((status) => _fetchOrdersByStatus(
                status, inclusiveStartDate, exclusiveEndDate))
            .toList();

    final List<List<QueryDocumentSnapshot>> results =
        await Future.wait(futures);
    final List<QueryDocumentSnapshot> allOrderDocs =
        results.expand((docs) => docs).toList();

    final productsSnapshot = await _db.collection('products').get();
    final productsMap = {
      for (var doc in productsSnapshot.docs) doc.id: Product.fromFirestore(doc)
    };

    final salesAggregation = <String, int>{};

    for (var orderDoc in allOrderDocs) {
      final orderData = app_order.Order.fromFirestore(orderDoc);
      for (var productInOrder in orderData.products) {
        salesAggregation.update(
          productInOrder.productId,
          (value) => value + productInOrder.quantity, // PERBAIKAN TYPO
          ifAbsent: () => productInOrder.quantity,
        );
      }
    }

    final List<ProductSalesData> reportData = [];
    salesAggregation.forEach((productId, totalSold) {
      final product = productsMap[productId];
      if (product != null) {
        reportData
            .add(ProductSalesData(product: product, totalSold: totalSold));
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
    final DateTime inclusiveStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime exclusiveEndDate =
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1));

    const List<String> statusVariations = [
      'processing',
      'Processing',
      'shipped',
      'Shipped',
      'delivered',
      'Delivered',
      'completed',
      'Completed'
    ];
    final List<Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
        futures = statusVariations
            .map((status) => _db
                .collection('orders')
                .where('date',
                    isGreaterThanOrEqualTo:
                        inclusiveStartDate.subtract(const Duration(days: 90)))
                .where('date', isLessThan: exclusiveEndDate)
                .where('status', isEqualTo: status)
                .get()
                .then((snapshot) => snapshot.docs))
            .toList();

    final List<List<QueryDocumentSnapshot>> results =
        await Future.wait(futures);
    final List<QueryDocumentSnapshot> allOrderDocs =
        results.expand((docs) => docs).toList();

    final List<ProductSalesHistory> history = [];

    for (var orderDoc in allOrderDocs) {
      final orderData = app_order.Order.fromFirestore(orderDoc);

      final DateTime transactionDate;
      if (orderData.shippedAt != null) {
        transactionDate = orderData.shippedAt!.toDate();
      } else {
        transactionDate = orderData.date.toDate();
      }

      if (transactionDate.isBefore(inclusiveStartDate) ||
          transactionDate.isAfter(exclusiveEndDate)) {
        continue;
      }

      for (var item in orderData.products) {
        if (item.productId == productId) {
          history.add(
            ProductSalesHistory(
              orderId: orderDoc.id,
              customerName: orderData.customer,
              orderDate: transactionDate,
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
