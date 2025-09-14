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
    // 1. Buat WriteBatch untuk memastikan semua operasi bersifat atomik
    final WriteBatch batch = _firestore.batch();
    final String transactionId = _uuid.v4(); // Buat ID unik untuk transaksi

    // 2. Buat referensi untuk dokumen di `purchase_transactions`
    final DocumentReference transactionRef = _firestore.collection('purchase_transactions').doc(transactionId);

    // 3. Konversi daftar item menjadi array of maps untuk disimpan di Firestore
    final List<Map<String, dynamic>> itemsArray = items.map((item) => {
      'productId': item.product.id,
      'productName': item.product.name,
      'quantity': item.quantity,
      'purchasePrice': item.purchasePrice,
      'subtotal': item.subtotal, // Simpan subtotal juga untuk analisis
    }).toList();

    // 4. Siapkan data untuk dokumen transaksi utama
    final transactionData = {
      'date': FieldValue.serverTimestamp(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'supplierId': supplier?.id,
      'supplierName': supplier?.name,
      'items': itemsArray, // Simpan sebagai array of maps
    };

    // Tambahkan operasi SET untuk dokumen transaksi ke dalam batch
    batch.set(transactionRef, transactionData);

    // 5. Loop melalui setiap item untuk membuat entri di `purchase_history` dan update stok
    for (final item in items) {
      // Buat ID unik untuk entri riwayat
      final String historyId = _uuid.v4();
      final DocumentReference historyRef = _firestore.collection('purchase_history').doc(historyId);

      // Siapkan data untuk dokumen riwayat
      final historyData = {
        'transactionId': transactionId, // Tautkan ke ID transaksi utama
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'purchasePrice': item.purchasePrice,
        'supplierName': supplier?.name, // Denormalisasi untuk kemudahan
        'purchaseDate': FieldValue.serverTimestamp(),
      };
      // Tambahkan operasi SET untuk dokumen riwayat ke dalam batch
      batch.set(historyRef, historyData);

      // 6. Update stok produk di koleksi `products`
      final DocumentReference productRef = _firestore.collection('products').doc(item.product.id);
      batch.update(productRef, {
        'stock': FieldValue.increment(item.quantity),
        // Juga perbarui harga beli terakhir jika diperlukan
        'purchasePrice': item.purchasePrice,
      });
    }

    // 7. Commit batch untuk menulis semua perubahan ke Firestore
    await batch.commit();
  }
}
