import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/purchase_cart_item.dart';

class Purchase {
  final String id;
  final String purchaseNumber;
  final String supplierId;
  final String supplierName;
  final List<PurchaseCartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final DateTime date; // <-- DIUBAH dari purchaseDate menjadi date
  final String status;

  Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.date, // <-- DIUBAH
    required this.status,
  });

  // Konversi ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'purchaseNumber': purchaseNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date), // <-- DIUBAH
      'status': status,
    };
  }

  // Buat dari Map Firestore
  factory Purchase.fromMap(String id, Map<String, dynamic> map) {
    return Purchase(
      id: id,
      purchaseNumber: map['purchaseNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      items: (map['items'] as List)
          .map((itemMap) => PurchaseCartItem.fromMap(itemMap))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      date: (map['date'] as Timestamp).toDate(), // <-- DIUBAH
      status: map['status'] ?? '',
    );
  }
}
