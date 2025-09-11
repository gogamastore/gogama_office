# Blueprint Proyek: Aplikasi Manajemen Inventaris & Pesanan

Dokumen ini adalah sumber kebenaran tunggal untuk gaya, desain, dan fitur aplikasi. Dokumen ini diperbarui secara otomatis setelah setiap perubahan.

---

## 1. Ringkasan & Tujuan Aplikasi

Aplikasi ini adalah sistem manajemen inventaris dan pesanan yang komprehensif, dibangun menggunakan Flutter dan Riverpod. Tujuannya adalah untuk menyediakan alat yang mudah digunakan bagi pemilik bisnis untuk melacak produk, mengelola stok, memproses pesanan penjualan, dan mencatat pembelian dari pemasok.

---

## 2. Fitur, Desain, & Arsitektur yang Telah Diimplementasikan

### A. Arsitektur & Teknologi
- **Framework**: Flutter
- **Manajemen State**: `flutter_riverpod` untuk manajemen state yang reaktif dan terukur.
- **Navigasi**: Menggunakan `Navigator` bawaan Flutter dengan `MaterialPageRoute`.
- **Struktur Proyek**: Kode diorganisir berdasarkan fitur (misalnya, `screens/products`, `screens/orders`, `screens/purchases`).
- **Layanan (Services)**: Logika bisnis dan interaksi backend (misalnya, Firestore) dienkapsulasi dalam kelas-kelas layanan (misalnya, `OrderService`).

### B. Fitur Utama

**1. Manajemen Produk:**
- **Tampilan Daftar Produk**: Halaman `products_screen.dart` menampilkan semua produk dalam `ListView`.
- **Pencarian Produk**: Fungsi pencarian *real-time* berdasarkan nama atau SKU produk.
- **Detail Produk**: Menampilkan informasi penting seperti gambar, nama, SKU, harga jual, harga beli, dan jumlah stok.
- **Placeholder Aksi**: Tombol untuk "Tambah Produk", "Impor", dan "Manajemen Stok" telah disiapkan di UI.

**2. Manajemen Pesanan (Orders):**
- **Tampilan Daftar Pesanan**: Halaman `orders_screen.dart` menampilkan semua pesanan dengan statusnya masing-masing.
- **Halaman Detail Pesanan**: Menampilkan rincian lengkap pesanan, termasuk:
  - Nomor pesanan, tanggal, dan status (misalnya, 'Pending', 'Processing').
  - Informasi pelanggan (nama, telepon, alamat).
  - Daftar produk yang dipesan beserta kuantitas dan subtotal.
  - Rincian biaya (subtotal, ongkos kirim, dan total akhir).
  - Informasi pembayaran (metode, status, dan tautan ke bukti bayar).
- **Edit Pesanan**: Pengguna dapat mengedit pesanan yang sudah ada melalui halaman layar penuh (`edit_order_screen.dart`). Fitur ini memungkinkan:
  - Menambah atau menghapus produk dari pesanan.
  - Mengubah kuantitas setiap produk.
  - Memperbarui biaya pengiriman.
  - Kalkulasi ulang total secara otomatis.

**3. Manajemen Pembelian (Purchases):**
- **Proses Pembelian Baru**: Alur untuk membuat catatan pembelian baru dari pemasok (`process_purchase_screen.dart`).
- **Keranjang Pembelian**: Pengguna dapat menambahkan item ke "keranjang pembelian" sebelum finalisasi (`purchase_cart_screen.dart`).

### C. Desain & UI/UX
- **Gaya Desain**: Mengadopsi Material Design dengan tata letak berbasis `Card` yang bersih dan modern.
- **Ikonografi**: Menggunakan paket `ionicons` untuk ikon yang konsisten dan jelas.
- **Tipografi**: Hirarki visual yang jelas untuk judul, subtitel, dan teks isi.
- **Palet Warna**: Skema warna yang didominasi oleh `Color(0xFF5DADE2)` (biru) sebagai aksen, dengan latar belakang netral (`Color(0xFFF8F9FA)`) dan teks gelap (`Color(0xFF2C3E50)`).
- **Umpan Balik Pengguna**: Menggunakan `SnackBar` untuk notifikasi (misalnya, "Pesanan berhasil diperbarui") dan `CircularProgressIndicator` saat memuat data.

---

## 3. Rencana & Langkah Perubahan Terbaru

Berikut adalah log dari perubahan terakhir yang diminta dan berhasil diimplementasikan.

### Sesi Perbaikan Bug: `edit_order_screen.dart` (Terbaru)

**Tujuan**: Memperbaiki serangkaian *error* yang muncul setelah proses refaktor dari dialog ke halaman penuh, yang menyebabkan aplikasi tidak dapat di-*build*.

**Langkah-Langkah Eksekusi:**

1.  **✅ Analisis Error**: Mengidentifikasi beberapa *error* kritis di `edit_order_screen.dart`, termasuk pemanggilan metode, *provider*, dan nama *field* yang tidak valid.
2.  **✅ Investigasi Kode**: Memeriksa file `order_service.dart`, `order_provider.dart`, dan `order_product.dart` untuk menemukan nama yang benar.
3.  **✅ Implementasi Perbaikan**: Mengoreksi logika penyimpanan data agar sesuai dengan pola Riverpod, memperbaiki semua nama yang salah, dan menyelesaikan peringatan *linting*.
4.  **✅ Verifikasi**: Memastikan semua *error* terkait telah hilang dan fungsionalitas edit pesanan berjalan sesuai harapan.

### Permintaan: Mengubah Dialog "Edit Pesanan" Menjadi Halaman Penuh

**Tujuan**: Mengganti `AlertDialog` yang digunakan untuk mengedit pesanan dengan sebuah halaman `Scaffold` layar penuh agar lebih ramah pengguna.

**Langkah-Langkah Eksekusi:**

1.  **✅ Buat Halaman Baru**: Membuat file `lib/screens/orders/edit_order_screen.dart`.
2.  **✅ Pindahkan Logika**: Memigrasikan UI dan logika dari dialog lama ke halaman baru.
3.  **✅ Perbarui Navigasi**: Mengubah panggilan `showDialog` menjadi `Navigator.push` di `order_detail_screen.dart`.
4.  **✅ Pembersihan Kode**: Menghapus file dialog lama `edit_order_dialog.dart`.
5.  **✅ Perbaikan Error Awal**: Memperbaiki *error* `library_private_types_in_public_api` di `products_screen.dart`.
