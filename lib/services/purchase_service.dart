import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_cart_item.dart';
import '../models/purchase_history.dart';

// Definisi provider yang berlebihan sudah dihapus dari sini.

class PurchaseService {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  PurchaseService(this._firestore);

  Future<void> recordPurchase({
    required String supplierId,
    required String supplierName,
    required Timestamp purchaseDate,
    required List<PurchaseCartItem> items,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang pembelian kosong.');
    }

    final purchaseId = _uuid.v4();
    final batch = _firestore.batch();

    final purchaseRef = _firestore.collection('purchases').doc(purchaseId);
    batch.set(purchaseRef, {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'itemCount': items.length,
    });

    for (final item in items) {
      final itemRef = purchaseRef.collection('items').doc(item.product.id);
      batch.set(itemRef, item.toMap());

      final productRef = _firestore.collection('products').doc(item.product.id);
      
      batch.update(productRef, {
        'stock': FieldValue.increment(item.quantity),
        'lastPurchasePrice': item.purchasePrice,
      });
      
      final productHistoryRef = productRef.collection('purchase_history').doc();
      batch.set(productHistoryRef, {
        'purchaseId': purchaseId,
        'purchaseDate': purchaseDate,
        'supplierName': supplierName,
        'quantity': item.quantity,
        'purchasePrice': item.purchasePrice,
      });
    }

    await batch.commit();
  }

  Stream<List<PurchaseHistory>> getPurchaseHistoryForProduct(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('purchase_history')
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => PurchaseHistory.fromMap(doc.data())).toList());
  }
}
