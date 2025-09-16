import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_transaction.dart';

// Provider ini akan mengambil SEMUA transaksi pembelian.
final purchaseTransactionsProvider = StreamProvider<List<PurchaseTransaction>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final stream = firestore
      .collection('purchase_transactions')
      .orderBy('date', descending: true) // Urutkan dari yang terbaru
      .snapshots();

  return stream.map((snapshot) => snapshot.docs
      .map((doc) => PurchaseTransaction.fromFirestore(doc))
      .toList());
});

// Provider untuk mengambil semua URL gambar produk dan menyimpannya dalam map
// Ini akan diambil sekali dan digunakan oleh dialog faktur.
final productImagesProvider = FutureProvider<Map<String, String>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('products').get();

  final Map<String, String> imageMap = {};
  for (var doc in snapshot.docs) {
    final data = doc.data();
    // Asumsi field untuk gambar adalah 'imageUrl' atau 'image'
    final imageUrl = data['image'] as String? ?? data['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageMap[doc.id] = imageUrl;
    }
  }
  return imageMap;
});
