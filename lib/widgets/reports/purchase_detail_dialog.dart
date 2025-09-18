import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase.dart';

class PurchaseDetailDialog extends StatelessWidget {
  final Purchase purchase;

  const PurchaseDetailDialog({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    // --- LOGIKA UNTUK STATUS TRANSAKSI ---
    Widget statusWidget;
    if (purchase.paymentMethod.toLowerCase() == 'credit') {
      statusWidget = const Text(
        'Kredit',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      statusWidget = Text(purchase.status);
    }

    return AlertDialog(
      title: Text('Detail Transaksi #${purchase.purchaseNumber}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow('Supplier:', Text(purchase.supplierName)),
              _buildDetailRow('Tanggal:', Text(dateFormatter.format(purchase.date))),
              _buildDetailRow('Total:', Text(currencyFormatter.format(purchase.totalAmount))),
              _buildDetailRow('Metode Pembayaran:', Text(purchase.paymentMethod)),
              // --- MENGGUNAKAN WIDGET STATUS YANG SUDAH DIBUAT ---
              _buildDetailRow('Status Transaksi:', statusWidget),
              const Divider(height: 30, thickness: 1),
              const Text('Daftar Barang:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              // --- MEMBUAT DAFTAR BARANG SCROLLABLE ---
              _buildItemsTable(context, currencyFormatter),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Tutup'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  // Diperbarui untuk menerima Widget agar lebih fleksibel
  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, NumberFormat currencyFormatter) {
    // --- DIBUNGKUS DENGAN WIDGET SCROLL ---
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 48.0,
          dataRowMaxHeight: 48.0,
          headingTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Produk')),
            DataColumn(label: Text('Jml'), numeric: true),
            DataColumn(label: Text('Harga'), numeric: true),
            DataColumn(label: Text('Subtotal'), numeric: true),
          ],
          rows: purchase.items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.product.name)),
                DataCell(Text(item.quantity.toString())),
                DataCell(Text(currencyFormatter.format(item.purchasePrice))),
                DataCell(Text(currencyFormatter.format(item.subtotal))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
