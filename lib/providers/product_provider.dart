
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// 1. Definisikan kelas Service untuk mengelola logika produk
class ProductService {
  final FirebaseFirestore _firestore;

  ProductService(this._firestore);

  // Metode untuk mendapatkan stream semua produk, diurutkan berdasarkan nama
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Metode untuk memperbarui produk di Firestore
  Future<void> updateProduct(Product product) async {
    try {
      final productDoc = _firestore.collection('products').doc(product.id);
      await productDoc.update(product.toMap());
    } catch (e) {
      // Tambahkan logging atau penanganan error yang lebih spesifik jika perlu
      print('Error updating product: $e');
      rethrow; // Lemparkan kembali error agar UI bisa menanganinya
    }
  }

  // Anda bisa menambahkan metode lain di sini (add, delete, etc.)
}

// 2. Provider untuk instance Firestore (jika belum ada di file lain)
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// 3. Provider untuk mengekspos ProductService ke seluruh aplikasi
final productServiceProvider = Provider<ProductService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ProductService(firestore);
});

// 4. StreamProvider yang menggunakan ProductService untuk mendapatkan data
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  // Awasi (watch) service, sehingga jika service berubah, provider ini akan rebuild
  final productService = ref.watch(productServiceProvider);
  return productService.getProducts();
});
