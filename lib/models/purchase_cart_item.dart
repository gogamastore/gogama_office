
import 'package:myapp/models/product.dart'; // Path yang sudah diperbaiki

class PurchaseCartItem {
  final Product product;
  int quantity;
  double purchasePrice;

  PurchaseCartItem({
    required this.product,
    required this.quantity,
    required this.purchasePrice,
  });

  double get subtotal => quantity * purchasePrice;

  // Mengubah item menjadi Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      // Simpan data produk yang relevan untuk referensi
      'productDetails': product.toMap(), 
    };
  }

  // Membuat item dari Map Firestore (perhatikan pengambilan produk)
  factory PurchaseCartItem.fromMap(Map<String, dynamic> map) {
    return PurchaseCartItem(
      // Product.fromMap akan merekonstruksi objek Product
      product: Product.fromMap(map['productDetails']), 
      quantity: map['quantity'],
      purchasePrice: map['purchasePrice'].toDouble(),
    );
  }
}
