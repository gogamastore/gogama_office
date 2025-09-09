// lib/models/product_category.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final Timestamp createdAt;

  ProductCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductCategory(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}