import 'package:cloud_firestore/cloud_firestore.dart';
import './order_product.dart';

// --- FUNGSI HELPER UNTUK PARSING YANG AMAN ---

// Mengubah berbagai jenis data tanggal (Timestamp, DateTime) menjadi Timestamp
Timestamp _parseDate(dynamic date) {
  if (date is Timestamp) {
    return date; // Tipe sudah benar (umumnya dari mobile)
  }
  if (date is DateTime) {
    return Timestamp.fromDate(date); // Handle jika datanya DateTime (terkadang dari web)
  }
  // Fallback jika data null atau tipe tidak dikenal
  return Timestamp.now();
}

// Mengubah berbagai jenis data angka (double, int, String) menjadi double
double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
  return null;
}

class Order {
  final String id;
  final String customer;
  final String customerPhone;
  final String customerAddress;
  final Timestamp date;
  final String status;
  final String total;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentProofUrl;
  final String shippingMethod;
  final double? shippingFee;
  final List<OrderProduct> products;
  final Timestamp? updatedAt;

  Order({
    required this.id,
    required this.customer,
    required this.customerPhone,
    required this.customerAddress,
    required this.date,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentProofUrl,
    required this.shippingMethod,
    this.shippingFee,
    required this.products,
    this.updatedAt,
  });

  // FACTORY CONSTRUCTOR YANG SUDAH DIPERKUAT
  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> customerDetails = data['customerDetails'] as Map<String, dynamic>? ?? {};

    // Logika parsing total yang sudah ada (dipertahankan)
    dynamic totalValue = data['total'];
    String totalString;
    if (totalValue is num) {
      totalString = totalValue.toString();
    } else if (totalValue is String) {
      totalString = totalValue;
    } else {
      totalString = '0';
    }

    return Order(
      id: doc.id,
      customer: data['customer'] ?? 'N/A',
      customerPhone: customerDetails['whatsapp'] ?? '-',
      customerAddress: customerDetails['address'] ?? '-',
      
      // Menggunakan helper untuk parsing tanggal yang aman
      date: _parseDate(data['date']),
      
      status: data['status']?.toLowerCase() ?? 'pending',
      total: totalString,
      
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      paymentStatus: data['paymentStatus']?.toLowerCase() ?? 'unpaid',
      paymentProofUrl: data['paymentProofUrl'],
      
      shippingMethod: data['shippingMethod'] ?? 'N/A',
      // Menggunakan helper untuk parsing biaya kirim yang aman
      shippingFee: _parseDouble(data['shippingFee']),
      
      products: (data['products'] as List<dynamic>?)
              ?.map((item) => OrderProduct.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      // Menggunakan helper untuk parsing tanggal update yang aman
      updatedAt: data['updatedAt'] != null ? _parseDate(data['updatedAt']) : null,
    );
  }
}
