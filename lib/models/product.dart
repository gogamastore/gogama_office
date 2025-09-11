
import 'package:cloud_firestore/cloud_firestore.dart';

// Fungsi utilitas untuk mengubah berbagai format harga menjadi double
double parsePrice(dynamic price) {
  if (price is double) return price;
  if (price is int) return price.toDouble();
  if (price is String) {
    final sanitized = price.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }
  return 0.0;
}

class Product {
  final String id;
  final String name;
  final double price; // Harga Jual - DIJAMIN double
  final int stock;
  final String? sku; // DIJAMIN String atau null
  final String? image;
  final double? purchasePrice; // Harga Beli - DIJAMIN double

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.sku,
    this.image,
    this.purchasePrice,
  });

  // Serialisasi: Mengubah objek Product menjadi Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'sku': sku,
      'image': image,
      'purchasePrice': purchasePrice,
    };
  }

  // Deserialisasi: Membuat objek Product dari Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: parsePrice(map['price']),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sku: map['sku']?.toString(),
      image: map['image'] as String?,
      purchasePrice: parsePrice(map['purchasePrice']),
    );
  }


  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: parsePrice(data['price']),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      sku: data['sku']?.toString(),
      image: data['image'] as String?,
      purchasePrice: parsePrice(data['purchasePrice']),
    );
  }
}
