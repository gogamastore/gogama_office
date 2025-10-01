import 'package:flutter/material.dart';

class SupplierManagementScreen extends StatelessWidget {
  const SupplierManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Supplier'),
      ),
      body: const Center(
        child: Text('Halaman Manajemen Supplier'),
      ),
    );
  }
}
