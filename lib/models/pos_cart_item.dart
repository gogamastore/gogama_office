import 'package:myapp/models/product.dart';
import 'package:myapp/models/promotion_model.dart';
import 'package:myapp/models/order_item.dart';

class PosCartItem {
  final Product product;
  final int quantity;
  final Promotion? promo;

  PosCartItem({
    required this.product,
    required this.quantity,
    this.promo,
  });

  double get posPrice {
    return promo?.discountPrice ?? product.price;
  }

  double get subtotal {
    return posPrice * quantity;
  }

  PosCartItem copyWith({
    Product? product,
    int? quantity,
    Promotion? promo,
  }) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      promo: promo ?? this.promo,
    );
  }

  OrderItem toOrderItem() {
    return OrderItem(
      productId: product.id,
      name: product.name, // FIXED: Changed productName to name
      quantity: quantity,
      price: posPrice,
      imageUrl: product.image, // ADDED: Pass image URL
      sku: product.sku,       // ADDED: Pass SKU
    );
  }
}
