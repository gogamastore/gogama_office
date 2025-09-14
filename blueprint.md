# Blueprint Aplikasi Inventory Management

## Ringkasan

Aplikasi ini adalah sistem manajemen inventory yang dirancang untuk membantu pengguna melacak produk, mengelola pembelian dari supplier, mencatat penjualan, dan memantau data bisnis melalui laporan. Aplikasi ini dibangun dengan Flutter dan menggunakan Firebase sebagai backend.

## Desain & Fitur yang Sudah Diimplementasikan

### Arsitektur
- **State Management:** Menggunakan `flutter_riverpod` untuk manajemen state yang reaktif dan terukur.
- **Struktur Proyek:** Kode diorganisir berdasarkan fitur.

### Fitur Utama
- **Manajemen Produk:** CRUD (Create, Read, Update, Delete) untuk produk.
- **Manajemen Supplier:** CRUD untuk supplier.
- **Manajemen Pembelian:** Membuat keranjang pembelian, mengedit item, dan memproses transaksi.
- **Manajemen Pesanan:** CRUD (Create, Read, Update, Delete) untuk pesanan pelanggan.
- **Dashboard Utama:** Pusat navigasi aplikasi.

### Gaya & Desain
- **UI:** Menggunakan komponen Material Design 3.
- **Tampilan Daftar:** Menggunakan `ListView.builder` dengan `Card` untuk menampilkan item.

## Rencana Perubahan Saat Ini: Implementasi Fitur Validasi Pesanan (POS)

### Tujuan
Membuat alur kerja baru untuk memvalidasi item dalam pesanan menggunakan pemindai barcode sebelum mengubah status pesanan menjadi "Processing". Ini bertujuan untuk meningkatkan akurasi dan efisiensi dalam proses pemenuhan pesanan.

### Langkah-langkah Implementasi

1.  **Persiapan Aset & Dependensi:**
    *   Menambahkan package `audioplayers` ke `pubspec.yaml` untuk umpan balik suara.
    *   Membuat folder `assets/sounds/` dan meminta pengguna untuk menambahkan file `success.mp3` dan `error.mp3`.
    *   Mendeklarasikan folder aset di `pubspec.yaml`.

2.  **Tombol Validasi di Detail Pesanan:**
    *   Memodifikasi `lib/screens/orders/order_detail_screen.dart`.
    *   Menambahkan tombol "Validasi Pesanan" yang hanya muncul jika status pesanan adalah "Pending".
    *   Tombol ini akan menavigasikan pengguna ke halaman validasi baru.

3.  **Membuat Halaman Validasi Pesanan:**
    *   Membuat file baru: `lib/screens/orders/validate_order_screen.dart`.
    *   Halaman ini akan berisi:
        *   `TextField` untuk input barcode EAN-13.
        *   Daftar produk dalam pesanan, dengan status visual "belum divalidasi" atau "sudah divalidasi".
        *   Logika validasi real-time saat barcode di-scan.
        *   Umpan balik suara (sukses/gagal) saat validasi.
        *   Dialog untuk mengonfirmasi/mengedit jumlah saat produk berhasil divalidasi.
        *   Tombol "Konfirmasi" di bagian bawah yang akan aktif hanya setelah semua item divalidasi.

4.  **Membuat Halaman Ringkasan Validasi:**
    *   Membuat file baru: `lib/screens/orders/validated_order_summary_screen.dart`.
    *   Halaman ini akan menampilkan daftar produk yang sudah divalidasi.
    *   Akan ada tombol "Proses Pesanan" di bagian bawah.

5.  **Memperbarui Status Pesanan:**
    *   Menambahkan fungsi `updateOrderStatus(String orderId, String status)` di `lib/services/order_service.dart`.
    *   Mengekspos fungsi ini melalui `OrderProvider` di `lib/providers/order_provider.dart`.
    *   Tombol "Proses Pesanan" akan memanggil fungsi ini untuk mengubah status di Firestore menjadi "Processing".
