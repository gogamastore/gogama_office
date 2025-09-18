import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/purchase.dart';
import '../../services/report_service.dart';
import '../../widgets/reports/payable_list.dart'; // Widget ini akan kita buat selanjutnya

class PayableReportScreen extends StatefulWidget {
  const PayableReportScreen({super.key});

  @override
  State<PayableReportScreen> createState() => _PayableReportScreenState();
}

class _PayableReportScreenState extends State<PayableReportScreen> {
  final ReportService _reportService = ReportService();
  List<Purchase>? _reportData;
  bool _isLoading = false;

  // Default rentang tanggal: 1 bulan terakhir
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _reportData = null; // Kosongkan data sebelumnya
    });

    try {
      final data = await _reportService.generatePayableReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _reportData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghasilkan laporan utang: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Utang Dagang'),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          const Divider(height: 1),
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDateButton(true, 'Mulai', _startDate),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              _buildDateButton(false, 'Selesai', _endDate),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.analytics),
            label: const Text('Hasilkan Laporan'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _isLoading ? null : _generateReport,
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(bool isStartDate, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        TextButton(
          child: Text(DateFormat('dd MMM yyyy', 'id_ID').format(date)),
          onPressed: () => _selectDate(context, isStartDate),
        ),
      ],
    );
  }

  Widget _buildReportContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportData == null) {
      return const Center(
        child: Text('Pilih rentang tanggal dan hasilkan laporan untuk melihat data.'),
      );
    }

    if (_reportData!.isEmpty) {
      return const Center(
        child: Text('Tidak ada utang dagang untuk rentang tanggal yang dipilih.'),
      );
    }

    return PayableList(reportData: _reportData!);
  }
}
