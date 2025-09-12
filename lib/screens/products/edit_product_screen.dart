import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart'; // Impor provider produk

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  EditProductScreenState createState() => EditProductScreenState();
}

class EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.product.description);
    _selectedCategoryId = widget.product.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final newPrice = double.tryParse(_priceController.text) ?? 0.0;

      // Buat produk yang diperbarui menggunakan copyWith
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        sku: _skuController.text,
        price: newPrice,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
      );

      try {
        // Panggil provider untuk memperbarui produk
        await ref.read(productServiceProvider).updateProduct(updatedProduct);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan berhasil disimpan!')),
        );
        Navigator.of(context).pop(); // Kembali setelah berhasil
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final categoryNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: categoryNameController,
            decoration: const InputDecoration(hintText: "Nama Kategori"),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () async {
                final name = categoryNameController.text;
                if (name.isNotEmpty) {
                  try {
                    await ref.read(addCategoryProvider(name).future);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kategori "$name" berhasil ditambahkan.')),
                    );
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Detail Produk'),
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
              _buildPriceFields(currencyFormatter),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Deskripsi', 'Masukkan deskripsi produk', maxLines: 4, optional: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageEditor() {
    // TODO: Implement image picking and display logic
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFE0E6ED),
            backgroundImage: (widget.product.image != null && widget.product.image!.isNotEmpty) 
              ? NetworkImage(widget.product.image!) 
              : null,
            child: (widget.product.image == null || widget.product.image!.isEmpty) 
              ? const Icon(Icons.camera_alt, size: 50, color: Color(0xFFBDC3C7)) 
              : null,
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
        // Pastikan selectedCategoryId valid
        if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
           _selectedCategoryId = null;
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
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

  Widget _buildPriceFields(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final purchasePrice = widget.product.purchasePrice ?? 0.0;
            if (price < purchasePrice) {
              return 'Harga Jual tidak boleh lebih rendah dari Harga Beli (${currencyFormatter.format(purchasePrice)})';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Harga Beli (Tidak dapat diubah)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF2F4F4),
          ),
          child: Text(
            currencyFormatter.format(widget.product.purchasePrice ?? 0),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
         const SizedBox(height: 16),
         InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Stok (Tidak dapat diubah)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFF2F4F4),
          ),
          child: Text(
            widget.product.stock.toString(),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
