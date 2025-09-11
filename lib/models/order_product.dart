
// --- FUNGSI UTILITAS GLOBAL ---
// Fungsi ini akan menjadi satu-satunya sumber kebenaran untuk parsing harga.
double parsePrice(dynamic price) {
  if (price is double) return price;
  if (price is int) return price.toDouble();
  if (price is String) {
    // Hapus semua karakter non-numerik (Rp, titik, spasi)
    final sanitized = price.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }
  // Jika format tidak dikenali atau null, kembalikan 0.
  return 0.0;
}

class OrderProduct {
  final String productId;
  final String name;
  final int quantity;
  final double price; // DIJAMIN double

  OrderProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: json['productId'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      // --- GUNAKAN PARSER YANG KUAT DI SINI ---
      price: parsePrice(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price, // Harga yang disimpan DIJAMIN sudah double
    };
  }

  OrderProduct copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
  }) {
    return OrderProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
