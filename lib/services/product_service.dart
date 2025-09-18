import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/purchase_history_entry.dart';

class ProductService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference _purchaseHistoryCollection =
      FirebaseFirestore.instance.collection('purchase_history');

  // Mendapatkan semua produk secara real-time, diurutkan berdasarkan nama
  Stream<List<Product>> getProducts() {
    return _productsCollection.orderBy('name').snapshots().map((snapshot) {
      final products = <Product>[];
      for (var doc in snapshot.docs) {
        try {
          products.add(Product.fromFirestore(doc));
        } catch (e) {
          print('Gagal mem-parsing produk dengan ID: ${doc.id}, error: $e');
          // Lewati produk yang error dan lanjutkan
        }
      }
      return products;
    });
  }

  // Mendapatkan satu produk berdasarkan ID secara real-time
  Stream<Product?> getProductById(String productId) {
    return _productsCollection.doc(productId).snapshots().map((snapshot) {
      try {
        if (snapshot.exists) {
          return Product.fromFirestore(snapshot);
        }
      } catch (e) {
        print('Gagal mem-parsing produk dengan ID: $productId, error: $e');
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
    return _productsCollection.add(product.toMap());
  }

  // Memperbarui produk
  Future<void> updateProduct(Product product) {
    return _productsCollection.doc(product.id).update(product.toMap());
  }

  // Menghapus produk
  Future<void> deleteProduct(String productId) {
    return _productsCollection.doc(productId).delete();
  }
}
