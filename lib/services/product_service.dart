import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/purchase_history_entry.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _purchaseHistoryCollection = FirebaseFirestore.instance.collection('purchase_history');

  // Mendapatkan semua produk secara real-time, diurutkan berdasarkan nama
  Stream<List<Product>> getProducts() {
    // --- MODIFIKASI: Menambahkan orderBy untuk mengurutkan berdasarkan nama ---
    return _productsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Mendapatkan satu produk berdasarkan ID secara real-time
  Stream<Product?> getProductById(String productId) {
    return _productsCollection.doc(productId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Product.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Mengambil riwayat pembelian untuk produk tertentu
  Stream<List<PurchaseHistoryEntry>> getPurchaseHistory(String productId) {
    return _purchaseHistoryCollection
        .where('productId', isEqualTo: productId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PurchaseHistoryEntry.fromFirestore(doc))
          .toList();
    });
  }

  // Menambah produk baru
  Future<DocumentReference> addProduct(Product product) {
    // --- PERBAIKAN: Menggunakan toMap() bukan toFirestore() ---
    return _productsCollection.add(product.toMap());
  }

  // Memperbarui produk
  Future<void> updateProduct(Product product) {
    // --- PERBAIKAN: Menggunakan toMap() bukan toFirestore() ---
    return _productsCollection.doc(product.id).update(product.toMap());
  }

  // Menghapus produk
  Future<void> deleteProduct(String productId) {
    return _productsCollection.doc(productId).delete();
  }
}
