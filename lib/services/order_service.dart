import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../models/order.dart';
import '../models/product.dart';
import '../models/order_product.dart';
import '../models/order_item.dart'; // Impor OrderItem

class OrderService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<List<OrderProduct>> _enrichProducts(
      List<OrderProduct> orderProducts) async {
    if (orderProducts.isEmpty) return [];

    final productIds = orderProducts.map((p) => p.productId).toSet().toList();
    if (productIds.isEmpty) return [];

    final productSnapshots = await _db
        .collection('products')
        .where(firestore.FieldPath.documentId, whereIn: productIds)
        .get();

    final productMap = {
      for (var doc in productSnapshots.docs)
        doc.id: Product.fromFirestore(doc)
    };

    return orderProducts.map((orderProduct) {
      final productDetails = productMap[orderProduct.productId];
      return orderProduct.copyWith(
        name: productDetails?.name ?? orderProduct.name,
        sku: productDetails?.sku,
        imageUrl: productDetails?.image, // Gunakan 'image' dari Product
      );
    }).toList();
  }

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
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': firestore.Timestamp.now(),
    });
  }

  // --- PERBAIKAN: Secara konsisten menerima List<OrderItem> untuk update --
  Future<void> updateOrderDetails(String orderId, List<OrderItem> products,
      double shippingFee, double newTotal) async {
    final orderRef = _db.collection('orders').doc(orderId);

    // Ubah List<OrderItem> menjadi List<Map<String, dynamic>> untuk Firestore
    final productsAsJson = products.map((p) => p.toJson()).toList();

    await orderRef.update({
      'products': productsAsJson,
      'shippingFee': shippingFee,
      'total': newTotal.toInt(), // PERBAIKAN: Simpan sebagai integer
      'updatedAt': firestore.Timestamp.now(),
    });
  }
}
