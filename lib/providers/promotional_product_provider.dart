import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'product_provider.dart';

// Provider ini mengambil produk dan mengganti harganya jika ada promo yang aktif.
final promotionalProductsProvider = FutureProvider<List<Product>>((ref) async {
  // 1. Ambil daftar produk dasar
  final products = await ref.watch(allProductsProvider.future);

  // 2. Ambil semua data promosi dalam satu panggilan
  final promoSnapshot = await FirebaseFirestore.instance.collection('promotions').get();
  
  // 3. Ubah data promo menjadi Map untuk pencarian cepat
  final promoMap = <String, double>{};
  for (var doc in promoSnapshot.docs) {
    final data = doc.data();
    final productId = data['productId'];
    
    // PERBAIKAN: Gunakan 'discountPrice' sesuai struktur Firestore yang benar
    final promoPrice = parsePrice(data['discountPrice']); 

    if (productId != null && promoPrice > 0) { // Pastikan harga promo valid
      promoMap[productId] = promoPrice;
    }
  }

  // 4. Jika tidak ada promo, kembalikan produk asli
  if (promoMap.isEmpty) {
    return products;
  }

  // 5. Buat daftar produk baru dengan harga yang sudah diperbarui
  final promotionalProducts = products.map((product) {
    if (promoMap.containsKey(product.id)) {
      // Buat salinan produk dengan harga promo
      return product.copyWith(price: promoMap[product.id]);
    } else {
      // Kembalikan produk asli
      return product;
    }
  }).toList();

  return promotionalProducts;
});
