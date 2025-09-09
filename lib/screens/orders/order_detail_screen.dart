
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isEditing = false;
  List<OrderProduct> _editableProducts = [];
  late TextEditingController _shippingFeeController;

  @override
  void initState() {
    super.initState();
    _shippingFeeController = TextEditingController();
  }

  @override
  void dispose() {
    _shippingFeeController.dispose();
    super.dispose();
  }

  double _calculateNewTotal() {
    final productsTotal = _editableProducts.fold<double>(
        0.0, (sum, item) => sum + (item.price * item.quantity));
    final shippingFee = double.tryParse(_shippingFeeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    return productsTotal + shippingFee;
  }

  void _resetState(Order order) {
    _editableProducts = List<OrderProduct>.from(
        order.products.map((p) => OrderProduct.fromJson(p.toJson())));
    _shippingFeeController.text =
        NumberFormat.decimalPattern('id_ID').format(order.shippingFee ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailsProvider(widget.orderId));
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pesanan ${widget.orderId}', overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          orderAsync.when(
            data: (order) => order != null
                ? IconButton(
                    icon: Icon(_isEditing ? Ionicons.close_circle_outline : Ionicons.create_outline),
                    tooltip: _isEditing ? 'Batal' : 'Edit Pesanan',
                    onPressed: () {
                      final originalOrder = ref.read(orderDetailsProvider(widget.orderId)).value;
                      if (originalOrder == null) return;

                      setState(() {
                        if (_isEditing) {
                          // Exit edit mode, reset changes
                          _resetState(originalOrder);
                           _isEditing = false;
                        } else {
                          // Enter edit mode
                           _resetState(originalOrder);
                           _isEditing = true;
                        }
                      });
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }

          // Initialize state for the first time
          if (_editableProducts.isEmpty) {
            _resetState(order);
          }
          
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    if (_isEditing) _buildEditHeader(),
                    ..._editableProducts.map((product) {
                      final index = _editableProducts.indexOf(product);
                      return _buildProductTile(product, index);
                    }).toList(),
                    const Divider(height: 24, thickness: 1),
                     _buildShippingRow(),
                  ],
                ),
              ),
              _buildBottomSummary(currencyFormatter),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Gagal memuat pesanan: $err')),
      ),
    );
  }

  Widget _buildEditHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text('Edit Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
    );
  }

  Widget _buildProductTile(OrderProduct product, int index) {
     final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis,),
                const SizedBox(height: 4),
                // PERBAIKAN DEFINITIF: Mengganti Colors.grey[700] dengan nilai konstan
                Text(currencyFormatter.format(product.price), style: const TextStyle(color: Color(0xFF616161))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _isEditing 
          ? Row(
                children: [
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Ionicons.remove_circle, color: Colors.redAccent, size: 28),
                        onPressed: () {
                            if (product.quantity > 1) {
                                setState(() => product.quantity--);
                            }
                        },
                    ),
                    SizedBox(
                        width: 40,
                        child: Text(product.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Ionicons.add_circle, color: Colors.green, size: 28),
                        onPressed: () => setState(() => product.quantity++),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Ionicons.trash_outline, color: Colors.grey[600], size: 24),
                        onPressed: () => setState(() => _editableProducts.removeAt(index)),
                    ),
                ],
            )
          : Text('x ${product.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShippingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Biaya Pengiriman', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          _isEditing 
            ? SizedBox(
                width: 120,
                child: TextFormField(
                    controller: _shippingFeeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                    ),
                    onChanged: (value) => setState(() {}),
                ),
            )
            : Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(double.tryParse(_shippingFeeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)),
        ],
      ),
    );
  }


  Widget _buildBottomSummary(NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                Text(
                  currencyFormatter.format(_calculateNewTotal()),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3498DB)),
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                   final orderService = ref.read(orderServiceProvider);
                   await orderService.updateOrderDetails(
                     widget.orderId,
                     _editableProducts,
                     double.tryParse(_shippingFeeController.text.replaceAll(RegExp(r'[^0--9]'), '')) ?? 0,
                     _calculateNewTotal(),
                   );
                   ref.refresh(allOrdersProvider);
                   ref.refresh(orderDetailsProvider(widget.orderId));
                   setState(() {
                     _isEditing = false;
                   });
                },
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
