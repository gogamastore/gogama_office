import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/purchase_cart_item.dart';
import '../../models/supplier.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> processPurchaseTransaction({
    required List<PurchaseCartItem> items,
    required double totalAmount,
    required String paymentMethod,
    Supplier? supplier,
  }) async {
    final WriteBatch batch = _firestore.batch();
    final String transactionId = _uuid.v4();

    final DocumentReference transactionRef = _firestore.collection('purchase_transactions').doc(transactionId);

    final List<Map<String, dynamic>> itemsArray = items.map((item) => {
      'productId': item.product.id,
      'productName': item.product.name,
      'quantity': item.quantity,
      'purchasePrice': item.purchasePrice,
      'subtotal': item.subtotal,
    }).toList();

    // --- PERBAIKAN: Konversi totalAmount ke integer sebelum menyimpan ---
    final transactionData = {
      'date': FieldValue.serverTimestamp(),
      'totalAmount': totalAmount.toInt(), // Diubah menjadi integer
      'paymentMethod': paymentMethod,
      'supplierId': supplier?.id,
      'supplierName': supplier?.name,
      'items': itemsArray,
    };

    batch.set(transactionRef, transactionData);

    for (final item in items) {
      final String historyId = _uuid.v4();
      final DocumentReference historyRef = _firestore.collection('purchase_history').doc(historyId);

      final historyData = {
        'transactionId': transactionId,
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'purchasePrice': item.purchasePrice,
        'supplierName': supplier?.name,
        'purchaseDate': FieldValue.serverTimestamp(),
      };
      batch.set(historyRef, historyData);

      final DocumentReference productRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productRef, {
        'stock': FieldValue.increment(item.quantity),
        'purchasePrice': item.purchasePrice,
      });
    }

    await batch.commit();
  }
}
