// lib/models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_details.dart';
import 'order_product.dart';

class Order {
  final String id;
  final Timestamp date;
  String status;
  final String customer;
  final CustomerDetails? customerDetails;
  final String total;
  final String? paymentStatus;
  final List<OrderProduct> products;
  final String? paymentProofUrl;
  final String? shippingService;
  final double? shippingFee;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.customer,
    this.customerDetails,
    required this.total,
    this.paymentStatus,
    required this.products,
    this.paymentProofUrl,
    this.shippingService,
    this.shippingFee,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      date: data['date'] as Timestamp,
      // DIperbaiki: Tambahkan .trim() untuk menghapus spasi yang tidak diinginkan
      status: (data['status'] as String? ?? '').trim().toLowerCase(), 
      customer: data['customer'] ?? '',
      customerDetails: data['customerDetails'] != null
          ? CustomerDetails.fromJson(data['customerDetails'])
          : null,
      total: data['total']?.toString() ?? '0',
      paymentStatus: data['paymentStatus'],
      products: (data['products'] as List<dynamic>?)
          ?.map((item) => OrderProduct.fromJson(item))
          .toList() ?? [],
      paymentProofUrl: data['paymentProofUrl'],
      shippingService: data['shippingService'],
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0,
    );
  }
}
