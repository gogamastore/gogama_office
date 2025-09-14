import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseHistoryEntry {
  final String id;
  final String productId;
  final DateTime purchaseDate;
  final int quantity;
  // PERBAIKAN: Mengganti nama `unitPrice` menjadi `purchasePrice` agar konsisten
  final double purchasePrice;
  final String? supplierName;

  PurchaseHistoryEntry({
    required this.id,
    required this.productId,
    required this.purchaseDate,
    required this.quantity,
    required this.purchasePrice, // Diperbarui
    this.supplierName,
  });

  // Computed property untuk total biaya
  double get totalCost => quantity * purchasePrice; // Diperbarui

  // Factory constructor untuk membuat instance dari DocumentSnapshot Firestore
  factory PurchaseHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PurchaseHistoryEntry(
      id: doc.id,
      productId: data['productId'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      quantity: data['quantity'] ?? 0,
      // Diperbarui untuk membaca field 'price' dan mengassign ke `purchasePrice`
      purchasePrice: (data['price'] as num?)?.toDouble() ?? 0.0, 
      supplierName: data['supplierName'] as String?,
    );
  }
}
