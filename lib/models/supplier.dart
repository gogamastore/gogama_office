// lib/models/supplier.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String name;
  final String? whatsapp;
  final String? address;
  final Timestamp createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.whatsapp,
    this.address,
    required this.createdAt,
  });

  factory Supplier.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      name: data['name'],
      whatsapp: data['whatsapp'],
      address: data['address'],
      createdAt: data['createdAt'],
    );
  }
}
