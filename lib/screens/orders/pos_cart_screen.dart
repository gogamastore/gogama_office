import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/order_item.dart';
import 'package:myapp/models/pos_cart_item.dart';
import 'package:myapp/providers/pos_cart_provider.dart';
import 'package:myapp/screens/orders/pos_edit_item_dialog.dart';
import 'package:myapp/screens/orders/validated_order_summary_screen.dart';
import 'package:myapp/models/order.dart';

class PosCartScreen extends ConsumerWidget {
  final Order order;
  const PosCartScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(posCartProvider);
    final total = ref.watch(posTotalProvider);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // --- FIX: USE PosEditItemDialog ---
    void showEditDialog(PosCartItem cartItem) async {
      // Convert PosCartItem to OrderItem to be compatible with the dialog
      final orderItem = OrderItem(
        productId: cartItem.product.id,
        name: cartItem.product.name,
        price: cartItem.posPrice,
        quantity: cartItem.quantity,
        sku: cartItem.product.sku,
        imageUrl: cartItem.product.image,
      );

      final OrderItem? updatedItem = await showDialog<OrderItem>(
        context: context,
        // Use the correct dialog
        builder: (_) => PosEditItemDialog(product: orderItem),
      );

      if (updatedItem != null) {
        // The dialog now directly updates the provider, so we don't need to call setState or anything here.
        // The provider will notify the UI to rebuild.
      }
    }
    // --- END FIX ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Validasi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text('Keranjang masih kosong.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.quantity} x ${currencyFormatter.format(item.posPrice)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormatter.format(item.subtotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                onPressed: () => showEditDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => ref
                                    .read(posCartProvider.notifier)
                                    .removeItem(item.product.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildSummary(context, ref, total, currencyFormatter, cartItems, order),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    WidgetRef ref,
    double total,
    NumberFormat currencyFormatter,
    List<PosCartItem> cartItems,
    Order order,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Keseluruhan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                currencyFormatter.format(total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: cartItems.isNotEmpty
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ValidatedOrderSummaryScreen(
                          orderId: order.id,
                          validatedItems: cartItems.map((e) => e.toOrderItem()).toList(),
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Lanjutkan ke Ringkasan'),
          ),
        ],
      ),
    );
  }
}
