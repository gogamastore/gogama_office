import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase.dart';

class PayableList extends StatelessWidget {
  final List<Purchase> reportData;

  const PayableList({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Supplier')),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Metode Pembayaran')),
            DataColumn(label: Text('Status Pembayaran')),
            DataColumn(label: Text('Status Transaksi')),
          ],
          rows: reportData.map((purchase) {
            return DataRow(
              cells: [
                // --- PERBAIKAN FINAL DI SINI ---
                DataCell(Text(DateFormat('dd MMM yy', 'id_ID').format(purchase.purchaseDate))), // <-- Menggunakan purchaseDate
                DataCell(Text(purchase.supplierName)),
                DataCell(Text(currencyFormatter.format(purchase.totalAmount))),
                DataCell(Text(purchase.paymentMethod)),
                DataCell(
                  Text(
                    'Kredit',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text(purchase.status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
