
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_category.dart';

// Provider untuk mengakses instance Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// StreamProvider untuk mendapatkan daftar kategori produk secara real-time
final categoriesStreamProvider = StreamProvider<List<ProductCategory>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('product_categories')
      .orderBy('name') // Urutkan berdasarkan nama
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .toList());
});

// FutureProvider untuk menambahkan kategori baru
// (Ini bisa digabung menjadi sebuah class CategoryService jika lebih kompleks)
final addCategoryProvider = FutureProvider.family<void, String>((ref, categoryName) async {
  if (categoryName.trim().isEmpty) {
    throw Exception('Nama kategori tidak boleh kosong.');
  }
  final firestore = ref.watch(firestoreProvider);
  await firestore.collection('product_categories').add({
    'name': categoryName.trim(),
  });
});
