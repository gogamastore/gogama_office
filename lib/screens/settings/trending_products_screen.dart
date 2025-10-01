import 'package:flutter/material.dart';

class TrendingProductsScreen extends StatelessWidget {
  const TrendingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Trending'),
      ),
      body: const Center(
        child: Text('Halaman Produk Trending'),
      ),
    );
  }
}
