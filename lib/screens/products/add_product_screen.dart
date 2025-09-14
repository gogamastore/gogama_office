import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  AddProductScreenState createState() => AddProductScreenState();
}

class AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _purchasePriceController; // Controller untuk Harga Beli
  late TextEditingController _stockController; // Controller untuk Stok
  late TextEditingController _descriptionController;

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _priceController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _stockController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final name = _nameController.text;
      final sku = _skuController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final description = _descriptionController.text;

      final newProduct = Product(
        id: '', // ID akan digenerate oleh Firestore
        name: name,
        sku: sku,
        price: price,
        purchasePrice: purchasePrice,
        stock: stock,
        description: description,
        categoryId: _selectedCategoryId,
        image: null, // TODO: Implement image upload
      );

      try {
        await ref.read(productServiceProvider).addProduct(newProduct);

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Produk "$name" berhasil ditambahkan!')),
        );
        navigator.pop(); // Kembali setelah berhasil
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal menambah produk: $e')),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final categoryNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        // Simpan Navigator dan ScaffoldMessenger sebelum dialog
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: categoryNameController,
            decoration: const InputDecoration(hintText: "Nama Kategori"),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () async {
                final name = categoryNameController.text;
                if (name.isNotEmpty) {
                  try {
                    await ref.read(addCategoryProvider(name).future);
                    navigator.pop(); // Tutup dialog
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Kategori "$name" berhasil ditambahkan.')),
                    );
                  } catch (e) {
                     scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Gagal menambah kategori: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save), 
            onPressed: _saveProduct, 
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildImageEditor(),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Nama Produk', 'Masukkan nama produk'),
              const SizedBox(height: 16),
              _buildTextField(_skuController, 'SKU (Stock Keeping Unit)', 'Masukkan SKU', optional: true),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildPriceFields(),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Deskripsi', 'Masukkan deskripsi produk', maxLines: 4, optional: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageEditor() {
    // Placeholder untuk produk baru
    return Center(
      child: Stack(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFFE0E6ED),
            child: Icon(Icons.camera_alt, size: 50, color: Color(0xFFBDC3C7)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: () { /* TODO: Implement image picking */ },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool optional = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (optional ? ' (Opsional)' : ''),
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (!optional && (value == null || value.isEmpty)) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return categoriesAsync.when(
      data: (categories) {
        if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
           _selectedCategoryId = null;
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          hint: const Text('Pilih Kategori'),
          isExpanded: true,
          items: categories.map((ProductCategory category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          decoration: InputDecoration(
            labelText: 'Kategori',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAddCategoryDialog,
              tooltip: 'Tambah Kategori Baru',
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Gagal memuat kategori: $err'),
    );
  }

  Widget _buildPriceFields() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Harga Jual
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Harga Jual',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Harga Jual tidak boleh kosong';
            }
            final price = double.tryParse(value) ?? 0.0;
            final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
            if (price < purchasePrice) {
              return 'Harga Jual tidak boleh lebih rendah dari Harga Beli (${currencyFormatter.format(purchasePrice)})';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Harga Beli
        TextFormField(
          controller: _purchasePriceController,
          decoration: const InputDecoration(
            labelText: 'Harga Beli',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
           validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Harga Beli tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Stok Awal
        TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            labelText: 'Stok Awal',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
           validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Stok Awal tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }
}
