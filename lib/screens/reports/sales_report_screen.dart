import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ionicons/ionicons.dart';

import '../../models/sales_report_data.dart';
import '../../providers/sales_report_provider.dart';
import '../../providers/product_images_provider.dart';
import '../../utils/formatter.dart' as formatter;

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(salesReportProvider.notifier);
      final initialDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
      notifier.setDateRange(initialDateRange);
      notifier.generateReport();
    });
  }

  Future<void> _selectDateRange(SalesReportNotifier notifier) async {
    final state = ref.read(salesReportProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: state.selectedDateRange,
    );
    if (picked != null && picked != state.selectedDateRange) {
      notifier.setDateRange(picked);
      notifier.generateReport();
    }
  }

  void _resetFilter(SalesReportNotifier notifier) {
    final now = DateTime.now();
    final dateRange =
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    notifier.setDateRange(dateRange);
    notifier.generateReport();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesReportProvider);
    final notifier = ref.read(salesReportProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterCard(notifier, state),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: CircularProgressIndicator(),
              )) else if (state.errorMessage != null)
              Center(child: Text('Gagal memuat data: ${state.errorMessage}'))
            else if (state.reportData != null) ...[
              _buildMetrics(state.reportData!),
              const SizedBox(height: 16),
              _buildTrendsCard(state.reportData!),
              const SizedBox(height: 16),
              _buildTransactionsTable(state.reportData!),
            ] else
              const Center(child: Text('Tidak ada data untuk ditampilkan.')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(
      SalesReportNotifier notifier, SalesReportState state) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Data', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(notifier),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Ionicons.calendar_outline),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        state.selectedDateRange == null
                            ? 'Pilih Tanggal'
                            : '${DateFormat('dd MMM yyyy').format(state.selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(state.selectedDateRange!.end)}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Ionicons.refresh_outline),
                  onPressed: () => _resetFilter(notifier),
                  tooltip: 'Reset Filter',
                  style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(SalesReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Penjualan',
                formatter.formatCurrency(data.totalRevenue),
                Ionicons.cash_outline,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Laba Kotor',
                formatter.formatCurrency(data.grossProfit),
                Ionicons.wallet_outline,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'Total Pesanan',
          data.orders.length.toString(),
          Ionicons.document_text_outline,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      {Color? color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color ?? Colors.grey, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard(SalesReportData data) {
    final Map<DateTime, double> dailyTotals = {};
    for (var order in data.orders) {
      final date = DateTime(order.orderDate.toDate().year,
          order.orderDate.toDate().month, order.orderDate.toDate().day);
      dailyTotals.update(date, (value) => value + order.totalRevenue,
          ifAbsent: () => order.totalRevenue);
    }

    final spots = dailyTotals.entries.map((entry) {
      return FlSpot(entry.key.millisecondsSinceEpoch.toDouble(), entry.value);
    }).toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Penjualan', style: Theme.of(context).textTheme.titleLarge),
            Text('Visualisasi pendapatan harian',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            if (spots.length > 1)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData:
                        const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat('dd/MM').format(date),
                                  style: const TextStyle(fontSize: 10)),
                            );
                          },
                          interval: spots.length > 5
                              ? (spots.last.x - spots.first.x) / 4
                              : null,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                  NumberFormat.compactCurrency(
                                          locale: 'id_ID', symbol: 'Rp')
                                      .format(value),
                                  style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300)),
                    minX: spots.first.x,
                    maxX: spots.last.x,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true,
                            color: Theme.of(context).primaryColor.withAlpha(50)),
                      ),
                    ],
                  ),
                ),
              ) else
              const SizedBox(
                height: 200,
                child: Center(
                    child: Text('Data tidak cukup untuk menampilkan grafik.')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(SalesReportData data) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Aktifkan scroll horizontal
        child: ConstrainedBox(
           constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width), // Pastikan tabel memenuhi lebar layar
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Pelanggan')),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('Status')),
            ],
            rows: data.orders.map((order) {
              return DataRow(
                onSelectChanged: (isSelected) {
                  if (isSelected ?? false) {
                    _showInvoiceDialog(context, order);
                  }
                },
                cells: [
                  DataCell(Text(DateFormat('dd MMM yyyy')
                      .format(order.orderDate.toDate()))),
                  DataCell(
                      Text(order.customerName, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(formatter.formatCurrency(order.totalRevenue))),
                  DataCell(Text(_translateStatus(order.status))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

 String _translateStatus(String status) {
    switch (status) {
      case 'Processing':
        return 'Perlu Dikirim';
      case 'Shipped':
        return 'Selesai';
      case 'Delivered':
        return 'Dikirim';
      default:
        return status;
    }
  }

  void _showInvoiceDialog(BuildContext context, SalesReportOrder order) {
    final images = ref.watch(productImagesProvider);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 600),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Faktur Penjualan',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('#${order.orderId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Colors.grey,
                                  overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 16),
                      Text(
                          'Tanggal: ${DateFormat('dd MMMM yyyy').format(order.orderDate.toDate())}'),
                      Text('Pelanggan: ${order.customerName}'),
                      const Divider(height: 24),
                      Text('Rincian Produk Terjual',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width *
                                    0.75), 
                            child: images.when(
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (err, stack) =>
                                  const Center(child: Text('Gagal memuat gambar')),
                              data: (imageMap) {
                                return DataTable(
                                  columnSpacing: 18,
                                  columns: const [
                                    DataColumn(label: Text('Produk')),
                                    DataColumn(label: Text('Jml'), numeric: true),
                                    DataColumn(label: Text('Harga'), numeric: true),
                                    DataColumn(
                                        label: Text('Subtotal'), numeric: true),
                                  ],
                                  rows: order.items.map((item) {
                                    final imageUrl = imageMap[item.productId];
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              if (imageUrl != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                            color: Colors.grey),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                    item.productName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(item.quantity.toString())),
                                        DataCell(Text(formatter
                                            .formatCurrency(item.salePrice))),
                                        DataCell(Text(formatter
                                            .formatCurrency(item.totalSale))),
                                      ],
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDialogTotalRow(context, 'Total Penjualan',
                          formatter.formatCurrency(order.totalRevenue)),
                      _buildDialogTotalRow(context, 'Total Pokok (HPP)',
                          formatter.formatCurrency(order.totalCogs)),
                      _buildDialogTotalRow(
                          context, 'Laba Kotor',
                          formatter.formatCurrency(order.grossProfit),
                          isProfit: true),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogTotalRow(BuildContext context, String label, String value,
      {bool isProfit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isProfit ? Colors.green.shade700 : null,
                ),
          ),
        ],
      ),
    );
  }
}
