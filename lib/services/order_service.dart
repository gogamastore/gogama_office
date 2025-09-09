import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:intl/intl.dart'; // PERBAIKAN DEFINITIF: IMPORT

import '../models/order.dart';
import '../models/order_product.dart';

class OrderService {
  final _db = firestore.FirebaseFirestore.instance;

  Future<List<Order>> getAllOrders() async {
    firestore.Query query = _db.collection('orders').orderBy('date', descending: true);
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      try {
        return Order.fromFirestore(doc as firestore.DocumentSnapshot);
      } catch (e) {
        print('Error parsing dokumen ${doc.id}: $e');
        return null; 
      }
    }).where((order) => order != null).cast<Order>().toList();
  }

  Future<Map<String, int>> getOrdersByStatus() async {
    final snapshot = await _db.collection('orders').get();
    final Map<String, int> counts = {
      'pending': 0,
      'processing': 0,
      'shipped': 0,
      'delivered': 0,
      'cancelled': 0,
    };

    for (var doc in snapshot.docs) {
      final status = (doc.data()['status'] as String?)?.toLowerCase().trim();
      if (status != null && counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<Order?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return Order.fromFirestore(doc as firestore.DocumentSnapshot);
    }
    return null;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    String statusToUpdate = newStatus.isNotEmpty ? newStatus[0].toUpperCase() + newStatus.substring(1) : '';
    await _db.collection('orders').doc(orderId).update({
      'status': statusToUpdate,
      'updatedAt': firestore.Timestamp.now(),
    });
  }

  Future<void> updateOrderDetails(String orderId, List<OrderProduct> products, double shippingFee, double newTotal) async {
    final orderRef = _db.collection('orders').doc(orderId);

    final productsAsJson = products.map((p) => p.toJson()).toList();

    await orderRef.update({
      'products': productsAsJson,
      'shippingFee': shippingFee,
      'total': 'Rp ${NumberFormat.decimalPattern('id_ID').format(newTotal)}',
      'updatedAt': firestore.Timestamp.now(),
    });
  }
}
