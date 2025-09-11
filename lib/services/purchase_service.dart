
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_cart_item.dart';
import '../models/supplier.dart';

class PurchaseService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Memproses seluruh transaksi pembelian menggunakan Firestore WriteBatch.
  ///
  /// Alur ini memastikan semua operasi (membuat transaksi, memperbarui stok, 
  /// dan mencatat riwayat) berhasil atau gagal bersamaan (atomik).
  Future<void> processPurchaseTransaction({
    required List<PurchaseCartItem> items,
    required double totalAmount,
    required String paymentMethod,
    Supplier? supplier, // Supplier sekarang opsional
  }) async {
    final batch = _db.batch();
    final now = Timestamp.now();
    
    // 1. Membuat Dokumen di `purchase_transactions`
    final transactionId = _uuid.v4();
    final transactionRef = _db.collection('purchase_transactions').doc(transactionId);

    batch.set(transactionRef, {
      'date': now,
      'totalAmount': totalAmount,
      'supplierId': supplier?.id,
      'supplierName': supplier?.name,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'purchasePrice': item.purchasePrice,
      }).toList(),
    });

    // 2. Memperbarui Stok & Harga di `products` dan Membuat Log di `purchase_history`
    for (final item in items) {
      final productRef = _db.collection('products').doc(item.product.id);
      
      // Operasi pembaruan untuk koleksi `products`
      batch.update(productRef, {
        // Menambah stok yang ada dengan kuantitas baru
        'stock': FieldValue.increment(item.quantity),
        // Memperbarui harga beli terakhir
        'purchasePrice': item.purchasePrice, 
      });

      // Operasi pembuatan log untuk koleksi `purchase_history`
      final historyId = _uuid.v4();
      final historyRef = _db.collection('purchase_history').doc(historyId);
      
      batch.set(historyRef, {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'purchasePrice': item.purchasePrice,
        'purchaseDate': now,
        'supplierName': supplier?.name, // Bisa null jika tidak ada supplier
        'transactionId': transactionId, // Referensi ke transaksi utama
      });
    }

    // 3. Menjalankan Semua Operasi dalam Batch
    await batch.commit();
  }
}
