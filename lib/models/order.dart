import 'package:cloud_firestore/cloud_firestore.dart';
import './order_product.dart';

// --- FUNGSI HELPER UNTUK PARSING YANG AMAN ---

// ... (helper functions exist here, no changes needed)
Timestamp _parseDate(dynamic date) {
  if (date is Timestamp) {
    return date; // Tipe sudah benar
  }
  if (date is DateTime) {
    return Timestamp.fromDate(date); // Handle jika datanya DateTime
  }
  // Fallback jika data null atau tipe tidak dikenal
  return Timestamp.now();
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
  return null;
}

String _parseString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

String? _parseStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
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

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> customerDetails =
        data['customerDetails'] as Map<String, dynamic>? ?? {};

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
      customer: _parseString(data['customer'], defaultValue: 'N/A'),
      customerPhone: _parseString(customerDetails['whatsapp'], defaultValue: '-'),
      customerAddress: _parseString(customerDetails['address'], defaultValue: '-'),
      date: _parseDate(data['date']),
      status: _parseString(data['status'], defaultValue: 'pending').toLowerCase(),
      total: totalString, 
      paymentMethod: _parseString(data['paymentMethod'], defaultValue: 'N/A'),
      paymentStatus: _parseString(data['paymentStatus'], defaultValue: 'unpaid').toLowerCase(),
      paymentProofUrl: _parseStringOrNull(data['paymentProofUrl']),
      shippingMethod: _parseString(data['shippingMethod'], defaultValue: 'N/A'),
      shippingFee: _parseDouble(data['shippingFee']),
      products: (data['products'] as List<dynamic>?)
              ?.map(
                  (item) => OrderProduct.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt:
          data['updatedAt'] != null ? _parseDate(data['updatedAt']) : null,
    );
  }

  // --- PENAMBAHAN: Metode copyWith ---
  Order copyWith({
    String? id,
    String? customer,
    String? customerPhone,
    String? customerAddress,
    Timestamp? date,
    String? status,
    String? total,
    String? paymentMethod,
    String? paymentStatus,
    // Izinkan null untuk tipe data yang bisa null
    String? paymentProofUrl,
    bool allowNullPaymentProofUrl = false,
    String? shippingMethod,
    double? shippingFee,
    bool allowNullShippingFee = false,
    List<OrderProduct>? products,
    Timestamp? updatedAt,
    bool allowNullUpdatedAt = false,
  }) {
    return Order(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      date: date ?? this.date,
      status: status ?? this.status,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofUrl: allowNullPaymentProofUrl ? paymentProofUrl : (paymentProofUrl ?? this.paymentProofUrl),
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingFee: allowNullShippingFee ? shippingFee : (shippingFee ?? this.shippingFee),
      products: products ?? this.products,
      updatedAt: allowNullUpdatedAt ? updatedAt : (updatedAt ?? this.updatedAt),
    );
  }
}
