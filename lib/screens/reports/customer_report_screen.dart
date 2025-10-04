import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/reports/customer_report_model.dart';
import '../../providers/report_provider.dart';
import 'customer_history_dialog.dart'; // Akan kita buat setelah ini

class CustomerReportScreen extends ConsumerWidget {
  const CustomerReportScreen({super.key});

  // Fungsi untuk memformat mata uang
  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  // Fungsi untuk menampilkan date range picker
  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final initialDateRange = ref.read(dateRangeProvider);
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      ref.read(dateRangeProvider.notifier).state = newDateRange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsData = ref.watch(customerReportProvider);
    final dateRange = ref.watch(dateRangeProvider);

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pelanggan'),
      ),
      body: Column(
        children: [
          // --- CARD UNTUK FILTER ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter Data', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Tombol untuk memilih tanggal
                    InkWell(
                      onTap: () => _selectDateRange(context, ref),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Rentang Tanggal',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Ionicons.calendar_outline),
                        ),
                        child: Text(
                          dateRange == null
                              ? 'Semua Tanggal'
                              : '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol Filter dan Reset
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Ionicons.funnel_outline),
                            label: const Text('Filter'),
                            onPressed: () { 
                              // Di Flutter dengan Riverpod, UI otomatis update saat state berubah
                              // jadi tombol ini sebenarnya tidak perlu. Tapi kita biarkan untuk UX
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Laporan diperbarui sesuai filter.')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            child: const Text('Reset'),
                            onPressed: () => ref.read(dateRangeProvider.notifier).state = null,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          // --- TABEL DATA --- 
          Expanded(
            child: reportsData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(child: Text('Tidak ada data untuk periode ini.'));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nama Pelanggan')),
                        DataColumn(label: Text('Jml. Transaksi'), numeric: true),
                        DataColumn(label: Text('Total Belanja'), numeric: true),
                        DataColumn(label: Text('Total Piutang'), numeric: true),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: reports.map((report) => _buildReportRow(context, report)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membangun setiap baris pada tabel
  DataRow _buildReportRow(BuildContext context, CustomerReport report) {
    return DataRow(
      cells: [
        DataCell(Text(report.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(report.transactionCount.toString())),
        DataCell(Text(_formatCurrency(report.totalSpent))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: report.receivables > 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatCurrency(report.receivables),
              style: TextStyle(color: report.receivables > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Ionicons.document_text_outline, color: Colors.blueAccent),
            tooltip: 'Lihat Riwayat Transaksi',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomerHistoryDialog(customerReport: report),
              );
            },
          ),
        ),
      ],
    );
  }
}
