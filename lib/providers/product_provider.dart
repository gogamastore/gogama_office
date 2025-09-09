// lib/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/product_category.dart'; // Tambahkan baris ini
import '../services/product_service.dart';

final productService = Provider<ProductService>((ref) => ProductService());

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.watch(productService).getProducts();
});

final productCategoriesProvider = FutureProvider.autoDispose<List<ProductCategory>>((ref) async {
  return ref.watch(productService).getProductCategories();
});