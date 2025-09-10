import 'package:cloud_firestore/cloud_firestore.dart';
import './order_product.dart';

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
    // Ambil nested map dengan aman, sekarang dinamai customerDetails
    Map<String, dynamic> customerDetails = data['customerDetails'] as Map<String, dynamic>? ?? {};

    return Order(
      id: doc.id,
      customer: data['customer'] ?? 'N/A',
      customerPhone: customerDetails['whatsapp'] ?? '-',
      customerAddress: customerDetails['address'] ?? '-',
      date: data['date'] ?? Timestamp.now(),
      status: data['status']?.toLowerCase() ?? 'pending',
      total: data['total'] ?? 'Rp 0',
      
      // --- PERBAIKAN KRUSIAL DI SINI ---
      // Mengambil data dari dalam map 'customerdetails', bukan dari luar
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      paymentStatus: data['paymentStatus']?.toLowerCase() ?? 'unpaid',
      paymentProofUrl: data['paymentProofUrl'],
      
      shippingMethod: data['shippingMethod'] ?? 'N/A',
      shippingFee: (data['shippingFee'] as num?)?.toDouble(),
      products: (data['products'] as List<dynamic>?)
              ?.map((item) => OrderProduct.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
