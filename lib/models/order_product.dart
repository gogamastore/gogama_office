class OrderProduct {
  final String productId;
  final String name;
  final int quantity;
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

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  // PENAMBAHAN: Metode copyWith untuk imutabilitas
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
