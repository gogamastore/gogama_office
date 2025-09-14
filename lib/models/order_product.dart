
// --- FUNGSI UTILITAS GLOBAL ---

// Mengubah harga (apapun formatnya) menjadi double.
double parsePrice(dynamic price) {
  if (price is double) return price;
  if (price is int) return price.toDouble();
  if (price is String) {
    final sanitized = price.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }
  return 0.0;
}

// *** BARU: Mengubah nilai (apapun formatnya) menjadi String atau null. ***
String? parseStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

class OrderProduct {
  final String productId;
  final String name;
  final int quantity;
  final double price; // DIJAMIN double
  final String? sku;
  final String? imageUrl;

  OrderProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.sku,
    this.imageUrl,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: json['productId'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: parsePrice(json['price']), // Menggunakan helper harga
      sku: parseStringOrNull(json['sku']), // *** DIPERBAIKI: Menggunakan helper string ***
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'sku': sku,
      'imageUrl': imageUrl,
    };
  }

  OrderProduct copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? sku,
    String? imageUrl,
  }) {
    return OrderProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
