import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_history_entry.dart';

class PurchaseHistoryDialog extends StatelessWidget {
  final String productId;

  const PurchaseHistoryDialog({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Riwayat Pembelian'),
      content: SizedBox(
        width: double.maxFinite,
        // PERBAIKAN: Query ke koleksi 'purchase_history' yang benar
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('purchase_history') // <-- TARGET KOLEKSI YANG BENAR
              .where('productId', isEqualTo: productId)
              .orderBy('purchaseDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Belum ada riwayat pembelian untuk produk ini.'));
            }

            final entries = snapshot.data!.docs.map((doc) {
              return PurchaseHistoryEntry.fromFirestore(doc);
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text('Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(entry.purchaseDate)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${entry.quantity}'),
                        Text('Harga Beli: ${currencyFormatter.format(entry.purchasePrice)}'),
                        // Tampilkan nama supplier jika ada
                        if (entry.supplierName != null && entry.supplierName!.isNotEmpty)
                           Text('Supplier: ${entry.supplierName}'),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${currencyFormatter.format(entry.quantity * entry.purchasePrice)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                     isThreeLine: true, // Beri ruang lebih untuk baris tambahan
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
