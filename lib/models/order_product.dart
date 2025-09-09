class OrderProduct {
  final String productId;
  final String name;
  int quantity;
  final double price;

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
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
    );
  }

  // Metode ini PENTING untuk menyimpan perubahan kembali ke Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
