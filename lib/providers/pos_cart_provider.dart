import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/pos_cart_item.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/models/promotion_model.dart';

class PosCartNotifier extends StateNotifier<List<PosCartItem>> {
  PosCartNotifier() : super([]);

  void addItem(Product product, int quantity, Promotion? promo) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      state = [
        for (final item in state)
          if (item.product.id == product.id)
            item.copyWith(quantity: item.quantity + quantity)
          else
            item,
      ];
    } else {
      state = [...state, PosCartItem(product: product, quantity: quantity, promo: promo)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  // --- FIX: ADDED updateItem METHOD ---
  void updateItem(String productId, int newQuantity, double newPrice) {
    state = [
      for (final item in state)
        if (item.product.id == productId) 
          item.copyWith(
            quantity: newQuantity, 
            // Create a new product instance with the updated price
            product: item.product.copyWith(price: newPrice),
            // Reset promo if price is manually changed
            promo: null 
          )
        else
          item,
    ];
  }
  // --- END FIX ---


  void clearCart() {
    state = [];
  }
}

final posCartProvider = StateNotifierProvider<PosCartNotifier, List<PosCartItem>>((ref) {
  return PosCartNotifier();
});

final posTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(posCartProvider);
  return cart.fold(0, (total, item) => total + item.subtotal);
});
