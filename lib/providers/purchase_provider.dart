import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/purchase_cart_item.dart';
import '../models/purchase_history.dart';
import '../services/purchase_service.dart';

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PurchaseService(firestore);
});

final purchaseHistoryProvider = StreamProvider.family<List<PurchaseHistory>, String>((ref, productId) {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.getPurchaseHistoryForProduct(productId);
});

final purchaseCartProvider = StateNotifierProvider<PurchaseCartNotifier, List<PurchaseCartItem>>((ref) {
  return PurchaseCartNotifier();
});

class PurchaseCartNotifier extends StateNotifier<List<PurchaseCartItem>> {
  PurchaseCartNotifier() : super([]);

  // Perbarui metode addProduct agar lebih cerdas
  void addProduct(Product product, double purchasePrice, int quantity) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      // Jika produk sudah ada, tambahkan kuantitas dan perbarui harga
      final existingItem = state[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity, // Tambah kuantitas yang ada
        purchasePrice: purchasePrice, // Selalu gunakan harga terakhir
      );
      state = [...state]..[existingIndex] = updatedItem;
    } else {
      // Jika produk belum ada, tambahkan item baru dengan kuantitas yang diberikan
      state = [
        ...state,
        PurchaseCartItem(product: product, quantity: quantity, purchasePrice: purchasePrice),
      ];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int newQuantity) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: newQuantity)
        else
          item,
    ];
  }

  void updatePrice(String productId, double newPrice) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(purchasePrice: newPrice)
        else
          item,
    ];
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.subtotal);
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
