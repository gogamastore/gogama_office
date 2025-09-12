import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseHistoryEntry {
  final DateTime purchaseDate;
  final int quantity;
  final double purchasePrice;
  final String productId;
  final String? supplierName; // Tambahkan supplierName

  PurchaseHistoryEntry({
    required this.purchaseDate,
    required this.quantity,
    required this.purchasePrice,
    required this.productId,
    this.supplierName, // Jadikan opsional
  });

  factory PurchaseHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Timestamp timestamp = data['purchaseDate'] ?? Timestamp.now();
    DateTime date = timestamp.toDate();

    return PurchaseHistoryEntry(
      purchaseDate: date,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      productId: data['productId'] ?? '',
      supplierName: data['supplierName'] as String?, // Ambil data supplierName
    );
  }
}
