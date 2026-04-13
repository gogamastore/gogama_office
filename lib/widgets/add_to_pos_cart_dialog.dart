import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/models/promotion_model.dart';
import 'package:myapp/providers/pos_cart_provider.dart';

class AddToPosCartDialog extends ConsumerStatefulWidget {
  final Product product;
  final Promotion? activePromo;

  const AddToPosCartDialog({super.key, required this.product, this.activePromo});

  @override
  ConsumerState<AddToPosCartDialog> createState() => _AddToPosCartDialogState();
}

class _AddToPosCartDialogState extends ConsumerState<AddToPosCartDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Stok tersedia: ${widget.product.stock}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                    });
                  }
                },
              ),
              Text('$_quantity'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_quantity < widget.product.stock) {
                    setState(() {
                      _quantity++;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(posCartProvider.notifier).addItem(
                  widget.product,
                  _quantity,
                  widget.activePromo,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
