import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';

class StockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> adjustStock({
    required String productId,
    required int quantity,
    required String type, 
    required String reason,
    required String userId,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    final adjustmentRef = _db.collection('stock_adjustments').doc();

    final int stockChange = type == 'in' ? quantity : -quantity;

    return _db.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw Exception("Produk tidak ditemukan!");
      }

      transaction.set(adjustmentRef, {
        'productId': productId,
        'quantity': quantity,
        'type': type,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'adjustedBy': userId,
      });

      transaction.update(productRef, {
        'stock': FieldValue.increment(stockChange),
      });
    });
  }

  Future<List<StockMovement>> getStockHistory(String productId) async {
    final productDoc = await _db.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw Exception('Produk dengan ID $productId tidak ditemukan.');
    }
    final product = Product.fromFirestore(productDoc);
    final int currentStock = product.stock;

    final salesFuture = _getSalesMovements(productId);
    final cancellationsFuture = _getCancellationMovements(productId);
    final purchasesFuture = _getPurchaseMovements(productId);
    final adjustmentsFuture = _getAdjustmentMovements(productId);

    final results = await Future.wait([
      salesFuture,
      cancellationsFuture,
      purchasesFuture,
      adjustmentsFuture,
    ]);

    final List<StockMovement> allMovements = results.expand((x) => x).toList();
    allMovements.sort((a, b) => b.date.compareTo(a.date));

    int runningStock = currentStock;
    final List<StockMovement> calculatedMovements = [];

    for (final movement in allMovements) {
      movement.stockAfter = runningStock;
      movement.stockBefore = runningStock - movement.change; 
      runningStock = movement.stockBefore;
      calculatedMovements.add(movement);
    }

    return calculatedMovements;
  }

  // --- MODIFIKASI: Menambahkan pemeriksaan null untuk field 'items' ---
  Future<List<StockMovement>> _getSalesMovements(String productId) async {
    final querySnapshot = await _db
        .collection('orders')
        .where('productIds', arrayContains: productId)
        .where('status', whereIn: ['Delivered', 'Shipped']).get();

    final List<StockMovement> movements = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      // Pengaman untuk menangani dokumen tanpa field 'items'
      if (data['items'] == null) continue;
      
      final items = List<Map<String, dynamic>>.from(data['items']);
      for (var item in items) {
        if (item['productId'] == productId) {
          movements.add(StockMovement(
            date: (data['date'] as Timestamp).toDate(),
            description: 'Penjualan - Order #${doc.id.substring(0, 6)}',
            change: -(item['quantity'] as int),
            type: StockMovementType.sale,
            referenceId: doc.id,
          ));
        }
      }
    }
    return movements;
  }

  // --- MODIFIKASI: Menambahkan pemeriksaan null untuk field 'items' ---
  Future<List<StockMovement>> _getCancellationMovements(String productId) async {
    final querySnapshot = await _db
        .collection('orders')
        .where('productIds', arrayContains: productId)
        .where('status', isEqualTo: 'Cancelled')
        .get();

    final List<StockMovement> movements = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      // Pengaman untuk menangani dokumen tanpa field 'items'
      if (data['items'] == null) continue;

      final items = List<Map<String, dynamic>>.from(data['items']);
      for (var item in items) {
        if (item['productId'] == productId) {
          movements.add(StockMovement(
            date: (data['date'] as Timestamp).toDate(),
            description: 'Pembatalan - Order #${doc.id.substring(0, 6)}',
            change: item['quantity'] as int,
            type: StockMovementType.cancellation,
            referenceId: doc.id,
          ));
        }
      }
    }
    return movements;
  }

  Future<List<StockMovement>> _getPurchaseMovements(String productId) async {
    final querySnapshot = await _db.collection('purchase_transactions').get();

    final List<StockMovement> movements = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['items'] == null) continue;
      final items = List<Map<String, dynamic>>.from(data['items']);
      for (var item in items) {
        if (item['productId'] == productId) {
          movements.add(StockMovement(
            date: (data['date'] as Timestamp).toDate(),
            description: 'Pembelian - Transaksi #${doc.id.substring(0, 6)}',
            change: item['quantity'] as int,
            type: StockMovementType.purchase,
            referenceId: doc.id,
          ));
        }
      }
    }
    return movements;
  }

  Future<List<StockMovement>> _getAdjustmentMovements(String productId) async {
    final querySnapshot = await _db
        .collection('stock_adjustments')
        .where('productId', isEqualTo: productId)
        .get();

    final List<StockMovement> movements = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String;
      final quantity = data['quantity'] as int;
      final change = type == 'in' ? quantity : -quantity;
      movements.add(StockMovement(
        date: (data['createdAt'] as Timestamp).toDate(),
        description: data['reason'] as String? ?? 'Penyesuaian Manual',
        change: change,
        type: type == 'in'
            ? StockMovementType.adjustmentIn
            : StockMovementType.adjustmentOut,
        referenceId: doc.id,
      ));
    }
    return movements;
  }
}
