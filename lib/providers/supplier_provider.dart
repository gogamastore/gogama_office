import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';

// Provider untuk instance Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider untuk mengambil daftar supplier
final suppliersProvider = StreamProvider<List<Supplier>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('suppliers')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Supplier.fromFirestore(doc)).toList());
});

// Provider untuk menambah supplier baru
final addSupplierProvider = FutureProvider.family<void, String>((ref, name) async {
  if (name.trim().isEmpty) {
    throw Exception('Nama supplier tidak boleh kosong.');
  }
  final firestore = ref.watch(firestoreProvider);
  await firestore.collection('suppliers').add({'name': name.trim()});
});
