
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/models/purchase_cart_item.dart';

// Provider untuk mengelola state dari keranjang pembelian
class PurchaseCartNotifier extends StateNotifier<List<PurchaseCartItem>> {
  PurchaseCartNotifier() : super([]);

  // Menambah produk ke keranjang atau memperbarui jumlah jika sudah ada
  void addItem(Product product, int quantity, double purchasePrice) {
    // Cek apakah item sudah ada
    final itemIndex = state.indexWhere((item) => item.product.id == product.id);

    if (itemIndex != -1) {
      // Jika ada, perbarui kuantitas dan harga (gunakan harga baru jika disediakan)
      final updatedItem = state[itemIndex];
      updatedItem.quantity += quantity;
      updatedItem.purchasePrice = purchasePrice; // Selalu perbarui dengan harga terakhir
      state = [...state];
    } else {
      // Jika tidak ada, tambahkan item baru
      state = [...state, PurchaseCartItem(product: product, quantity: quantity, purchasePrice: purchasePrice)];
    }
  }

  // Mengubah jumlah item di keranjang
  void updateItemQuantity(String productId, int newQuantity) {
    state = [
      for (final item in state)
        if (item.product.id == productId) 
          PurchaseCartItem(product: item.product, quantity: newQuantity, purchasePrice: item.purchasePrice)
        else
          item,
    ];
  }

  // Mengubah harga beli item di keranjang
  void updateItemPrice(String productId, double newPrice) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          PurchaseCartItem(product: item.product, quantity: item.quantity, purchasePrice: newPrice)
        else
          item,
    ];
  }

  // Menghapus item dari keranjang
  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  // Mengosongkan seluruh keranjang
  void clearCart() {
    state = [];
  }
}

final purchaseCartProvider = StateNotifierProvider<PurchaseCartNotifier, List<PurchaseCartItem>>((ref) {
  return PurchaseCartNotifier();
});

// Provider untuk menghitung total harga di keranjang
final purchaseTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(purchaseCartProvider);
  return cart.fold(0, (total, item) => total + item.subtotal);
});
