// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;

  Future<List<Product>> getProducts() async {
    final snapshot = await _db.collection('products').orderBy('name').get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add({...data, 'createdAt': Timestamp.now()});
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update({...data, 'updatedAt': Timestamp.now()});
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  Future<List<ProductCategory>> getProductCategories() async {
    final snapshot = await _db.collection('product_categories').orderBy('name').get();
    return snapshot.docs.map((doc) => ProductCategory.fromFirestore(doc)).toList();
  }
}