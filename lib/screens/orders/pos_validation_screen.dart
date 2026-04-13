import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../providers/pos_cart_provider.dart';
import 'scanner_screen.dart';
import 'pos_cart_screen.dart';
import 'pos_edit_item_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  final Order order;
  const PosScreen({super.key, required this.order});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final Map<String, OrderItem> _scannedProducts = {};
  late List<OrderItem> _unscannedProducts;

  final TextEditingController _manualInputController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posCartProvider.notifier).clearCart();
    });

    _unscannedProducts = widget.order.products.map((p) => OrderItem(
      productId: p.productId,
      name: p.name,
      price: p.price,
      quantity: p.quantity,
      sku: p.sku,
      imageUrl: p.imageUrl,
    )).toList();
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _findAndAddProduct(String sku) async {
    final productInOrder = _unscannedProducts.firstWhere(
      (p) => p.sku == sku,
      orElse: () =>
          OrderItem(productId: '', name: '', price: 0, quantity: 0, sku: sku),
    );

    if (productInOrder.productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'SKU tidak ditemukan dalam pesanan ini atau sudah divalidasi.'),
            backgroundColor: Colors.orange),
      );
      _playSound('sounds/error.mp3');
      return;
    }

    _playSound('sounds/success.mp3');
    final OrderItem? updatedItem = await showDialog<OrderItem>(
      context: context,
      builder: (_) => PosEditItemDialog(product: productInOrder),
    );

    if (updatedItem != null) {
      setState(() {
        _unscannedProducts.removeWhere((p) => p.sku == sku);
        _scannedProducts[sku] = updatedItem;

        final product = Product(
          id: updatedItem.productId,
          name: updatedItem.name,
          price: updatedItem.price, 
          sku: updatedItem.sku,
          image: updatedItem.imageUrl,
          stock: 0, 
        );
        ref
            .read(posCartProvider.notifier)
            .addItem(product, updatedItem.quantity, null);
      });
    }
    _manualInputController.clear();
  }

  Future<void> _playSound(String soundPath) async {
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      developer.log('Gagal memainkan suara: $e', name: 'PosScreen');
    }
  }

  Future<void> _navigateToScanner() async {
    try {
      final scannedValue = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
      if (scannedValue != null && scannedValue.isNotEmpty) {
        _findAndAddProduct(scannedValue);
      }
    } catch (e) {
      developer.log('Gagal membuka pemindai: $e', name: 'PosScreen');
    }
  }

 @override
  Widget build(BuildContext context) {
    final cartItemCount = ref.watch(posCartProvider).length;
    final unscannedTotal = _unscannedProducts.length;

    // --- FIX: IMPLEMETING USER'S SUGGESTED PopScope LOGIC ---
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Keluar'),
            content: const Text('Apakah Anda yakin ingin keluar dari halaman ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Hanya tutup dialog
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Keluar dari halaman validasi
                },
                child: const Text('Ya, Keluar'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validasi Pesanan'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40.0),
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order ID: ${widget.order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$cartItemCount item divalidasi',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, cartItemCount),
        body: Column(
          children: [
            _buildInputSection(),
            const Divider(height: 1, thickness: 1),
            Expanded(
                child: _unscannedProducts.isEmpty && _scannedProducts.isEmpty
                    ? const Center(child: Text('Pesanan ini tidak memiliki produk.'))
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                                'Belum Divalidasi ($unscannedTotal)',
                                Icons.inventory_2_outlined,
                                Colors.orange),
                          ),
                          if (_unscannedProducts.isNotEmpty)
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _unscannedProducts[index];
                                return _buildUnscannedItemTile(item);
                              },
                              childCount: _unscannedProducts.length,
                            ))
                          else
                            const SliverToBoxAdapter(
                              child: Center(
                                  child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Semua produk telah divalidasi.',
                                    style: TextStyle(color: Colors.green)),
                              )),
                            ),
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                                'Sudah Divalidasi ($cartItemCount)',
                                Icons.check_circle_outline,
                                Colors.green),
                          ),
                          if (_scannedProducts.isNotEmpty)
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item =
                                    _scannedProducts.values.elementAt(index);
                                return _buildScannedItemTile(item);
                              },
                              childCount: _scannedProducts.length,
                            ))
                          else
                            const SliverToBoxAdapter(
                              child: Center(
                                  child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Pindai produk untuk memulai validasi.'),
                              )),
                            ),
                        ],
                      )),
          ],
        ),
      ),
    );
    // --- END FIX ---
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _manualInputController,
              decoration: const InputDecoration(
                  labelText: 'Input atau Pindai SKU',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Ionicons.barcode_outline)),
              onSubmitted: (value) =>
                  (value.isNotEmpty) ? _findAndAddProduct(value) : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _navigateToScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pindai'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUnscannedItemTile(OrderItem item) {
    return ListTile(
      leading: CircleAvatar(child: Text('x${item.quantity}')),
      title: Text(item.name),
      subtitle: Text('SKU: ${item.sku}'),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_circle_down, color: Colors.blue),
        tooltip: 'Validasi manual',
        onPressed: () => _findAndAddProduct(item.sku!),
      ),
    );
  }

  Widget _buildScannedItemTile(OrderItem item) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text('x${item.quantity}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold))),
      title: Text(item.name,
          style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.lineThrough)),
      subtitle: Text('${currencyFormatter.format(item.price)} x ${item.quantity}'),
      trailing: Text(currencyFormatter.format(item.price * item.quantity),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomBar(BuildContext context, int cartItemCount) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PosCartScreen(order: widget.order),
            ));
          },
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('Lihat Keranjang Validasi'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
