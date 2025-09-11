
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// Provider untuk mengambil semua produk dari Firestore
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // --- TAMBAHKAN .orderBy('name') UNTUK MENGURUTKAN BERDASARKAN ABJAD ---
  return firestore.collection('products').orderBy('name').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  });
});
