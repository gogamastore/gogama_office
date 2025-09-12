import '../models/product.dart';

class PurchaseCartItem {
  final Product product;
  final int quantity;
  final double purchasePrice;

  PurchaseCartItem({
    required this.product,
    this.quantity = 1,
    required this.purchasePrice,
  });

  double get subtotal => quantity * purchasePrice;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'subtotal': subtotal,
    };
  }

  // Menambahkan metode copyWith yang hilang
  PurchaseCartItem copyWith({
    Product? product,
    int? quantity,
    double? purchasePrice,
  }) {
    return PurchaseCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
    );
  }
}
