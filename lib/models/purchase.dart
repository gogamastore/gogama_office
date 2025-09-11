
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/purchase_cart_item.dart'; // Path yang benar

class Purchase {
  final String id;
  final String purchaseNumber; 
  final String supplierId;
  final String supplierName;
  final List<PurchaseCartItem> items; // Tipe yang benar
  final double totalAmount;
  final String paymentMethod;
  final DateTime purchaseDate;
  final String status; // e.g., 'Completed', 'Pending'

  Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    required this.supplierName,
    required this.items, // Tipe yang benar
    required this.totalAmount,
    required this.paymentMethod,
    required this.purchaseDate,
    required this.status,
  });

  // Konversi ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'purchaseNumber': purchaseNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      // Ubah setiap item menjadi Map
      'items': items.map((item) => item.toMap()).toList(), 
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
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
      // Buat list of PurchaseCartItem dari list of map
      items: (map['items'] as List)
          .map((itemMap) => PurchaseCartItem.fromMap(itemMap))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      status: map['status'] ?? '',
    );
  }
}
