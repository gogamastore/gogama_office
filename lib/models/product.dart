// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String price;
  final double purchasePrice;
  final int stock;
  final String? image;
  final String? description;
  final Timestamp? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.purchasePrice,
    required this.stock,
    this.image,
    this.description,
    this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      // Perbaikan: Pastikan `sku` selalu diperlakukan sebagai String
      sku: (data['sku'] ?? '').toString(),
      category: data['category'] ?? '',
      // Perbaikan: Pastikan `price` selalu diperlakukan sebagai String
      price: (data['price'] ?? '').toString(),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      image: data['image'],
      description: data['description'],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}