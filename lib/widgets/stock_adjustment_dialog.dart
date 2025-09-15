import 'package:flutter/material.dart';
import '../../models/product.dart';

enum StockAdjustmentType { stockIn, stockOut }

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  StockAdjustmentType _adjustmentType = StockAdjustmentType.stockIn;
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final reason = _reasonController.text;
      Navigator.of(context).pop({
        'type': _adjustmentType,
        'quantity': quantity,
        'reason': reason,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Penyesuaian Stok'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Stok saat ini: ${widget.product.stock}',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              // --- PERUBAHAN DI SINI: Radio Buttons dalam Column ---
              Column(
                children: [
                  RadioListTile<StockAdjustmentType>(
                    title: const Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.green, size: 24),
                        SizedBox(width: 10),
                        Text('Stok Masuk',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    value: StockAdjustmentType.stockIn,
                    groupValue: _adjustmentType,
                    onChanged: (value) =>
                        setState(() => _adjustmentType = value!),
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: _adjustmentType == StockAdjustmentType.stockIn
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<StockAdjustmentType>(
                    title: const Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.red, size: 24),
                        SizedBox(width: 10),
                        Text('Stok Keluar',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    value: StockAdjustmentType.stockOut,
                    groupValue: _adjustmentType,
                    onChanged: (value) =>
                        setState(() => _adjustmentType = value!),
                    activeColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: _adjustmentType == StockAdjustmentType.stockOut
                              ? Colors.red
                              : Colors.grey.shade300,
                          width: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Input Jumlah
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  if (_adjustmentType == StockAdjustmentType.stockOut &&
                      val > widget.product.stock) {
                    return 'Stok keluar tidak boleh melebihi stok saat ini';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input Alasan
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Penyesuaian',
                  hintText: 'Contoh: Stok opname, barang rusak...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alasan tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _adjustmentType == StockAdjustmentType.stockIn
                ? Colors.green
                : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}
