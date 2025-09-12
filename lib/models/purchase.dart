import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  // purchaseNumber bisa jadi tidak ada di data lama, beri nilai default
  final String purchaseNumber; 
  final String supplierId;
  final String supplierName;
  final int itemCount; // Mengganti `items` dengan `itemCount`
  final double totalAmount;
  final String paymentMethod;
  final DateTime purchaseDate;
  // status bisa jadi tidak ada, beri nilai default
  final String status; 

  Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    required this.supplierName,
    required this.itemCount, // Diperbarui
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
      'itemCount': itemCount, // Diperbarui
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
      purchaseNumber: map['purchaseNumber'] ?? '', // Default value
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      itemCount: map['itemCount'] ?? 0, // Diperbarui dari `items`
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'Completed', // Default value
    );
  }
}
