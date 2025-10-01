import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order.dart';
import '../models/product.dart';
import '../models/order_product.dart';
import '../models/order_item.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  Future<void> markOrderAsPaid(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);
    await orderRef.update({
      'paymentStatus': 'Paid',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- FUNGSI YANG DIPERBAIKI ---
  Future<List<OrderProduct>> _enrichProducts(
      List<OrderProduct> orderProducts) async {
    if (orderProducts.isEmpty) return [];

    final productIds = orderProducts.map((p) => p.productId).toSet().toList();
    if (productIds.isEmpty) return [];

    final Map<String, Product> productMap = {};
    const chunkSize = 30; // Batas maksimum untuk kueri 'in' di Firestore

    // Pecah productIds menjadi beberapa bagian (chunk) yang lebih kecil
    for (var i = 0; i < productIds.length; i += chunkSize) {
      final chunk = productIds.sublist(
          i, i + chunkSize > productIds.length ? productIds.length : i + chunkSize);
      
      if (chunk.isNotEmpty) {
        // Jalankan kueri untuk setiap bagian (chunk)
        final productSnapshots = await _db
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        // Tambahkan hasil dari chunk ini ke dalam map utama
        for (var doc in productSnapshots.docs) {
          productMap[doc.id] = Product.fromFirestore(doc);
        }
      }
    }

    // Proses pemetaan tetap sama
    return orderProducts.map((orderProduct) {
      final productDetails = productMap[orderProduct.productId];
      return orderProduct.copyWith(
        name: productDetails?.name ?? orderProduct.name,
        sku: productDetails?.sku,
        imageUrl: productDetails?.image,
      );
    }).toList();
  }
  // --- AKHIR PERBAIKAN ---

  Future<List<Order>> getAllOrders() async {
    final snapshot =
        await _db.collection('orders').orderBy('date', descending: true).get();
    final orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    final enrichedOrders = await Future.wait(orders.map((order) async {
      final enrichedProducts = await _enrichProducts(order.products);
      return order.copyWith(products: enrichedProducts);
    }));
    return enrichedOrders;
  }

  Future<Order?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) {
      final order = Order.fromFirestore(doc);
      final enrichedProducts = await _enrichProducts(order.products);
      return order.copyWith(products: enrichedProducts);
    }
    return null;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final normalizedNewStatus = newStatus.toLowerCase();

    if (normalizedNewStatus == 'cancelled') {
      await _db.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) {
          throw Exception('Pesanan tidak ditemukan saat mencoba membatalkan.');
        }

        final orderData = Order.fromFirestore(orderSnapshot);
        
        if(orderData.status.toLowerCase() == 'cancelled'){
          return; // Jangan lakukan apa-apa jika sudah dibatalkan
        }

        for (final productInOrder in orderData.products) {
          final productRef = _db.collection('products').doc(productInOrder.productId);
          transaction.update(productRef, {'stock': FieldValue.increment(productInOrder.quantity)});
        }

        transaction.update(orderRef, {
          'status': 'Cancelled', 
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } else {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'Delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }

      await orderRef.update(updateData);
    }
  }

  // DIPERBARUI: Menambahkan parameter opsional 'validatorName'
  Future<void> updateOrderDetails(
    String orderId,
    List<OrderItem> newProducts,
    double shippingFee,
    double newTotal,
    {String? validatorName} // Parameter opsional
  ) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction((transaction) async {
      // FASE 1: BACA SEMUA DATA
      final oldOrderSnapshot = await transaction.get(orderRef);
      if (!oldOrderSnapshot.exists) {
        throw Exception('Pesanan tidak ditemukan!');
      }

      // FASE 2: LOGIKA & PERHITUNGAN (DALAM MEMORI)
      final oldOrderData = oldOrderSnapshot.data()!;
      final oldProducts = (oldOrderData['products'] as List)
          .map((p) => OrderItem.fromJson(p as Map<String, dynamic>))
          .toList();

      final Map<String, int> oldQuantities = {for (var p in oldProducts) p.productId: p.quantity};
      final Map<String, int> newQuantities = {for (var p in newProducts) p.productId: p.quantity};
      final allProductIds = {...oldQuantities.keys, ...newQuantities.keys};
      final Map<String, int> stockDelta = {};

      for (var productId in allProductIds) {
        final oldQty = oldQuantities[productId] ?? 0;
        final newQty = newQuantities[productId] ?? 0;
        final delta = newQty - oldQty;
        if (delta != 0) {
          stockDelta[productId] = -delta;
        }
      }

      // LANJUTAN FASE 1: BACA SEMUA PRODUK TERKAIT
      final Map<String, DocumentSnapshot> productSnapshots = {};
      for (final productId in stockDelta.keys) {
        productSnapshots[productId] = await transaction.get(_db.collection('products').doc(productId));
      }

      // FASE 3: VALIDASI (DALAM MEMORI)
      for (final entry in stockDelta.entries) {
        final productId = entry.key;
        final change = entry.value;
        final productSnapshot = productSnapshots[productId]!;

        if (!productSnapshot.exists) {
          throw Exception('Produk dengan ID $productId tidak ditemukan.');
        }
        final currentStock = (productSnapshot.data()! as Map<String, dynamic>)['stock'] as num;
        if (currentStock + change < 0) {
          final productName = (productSnapshot.data()! as Map<String, dynamic>)['name'] ?? 'N/A';
          throw Exception('Stok untuk "$productName" tidak mencukupi. Sisa: $currentStock, Dibutuhkan: ${-change}.');
        }
      }

      // FASE 4: TULIS SEMUA PERUBAHAN
      for (final entry in stockDelta.entries) {
        final productId = entry.key;
        final change = entry.value;
        transaction.update(_db.collection('products').doc(productId), {'stock': FieldValue.increment(change)});
      }

      final newProductsAsJson = newProducts.map((p) => p.toJson()).toList();
      
      // BARU: Siapkan data update dan tambahkan 'kasir' jika ada
      final Map<String, dynamic> updateData = {
        'products': newProductsAsJson,
        'productIds': newProducts.map((p) => p.productId).toList(),
        'shippingFee': shippingFee,
        'total': newTotal.toInt(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (validatorName != null) {
        updateData['kasir'] = validatorName;
      }

      transaction.update(orderRef, updateData);
    });
  }
}
