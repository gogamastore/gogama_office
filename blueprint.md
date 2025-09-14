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
- **Dashboard Utama:** Pusat navigasi aplikasi.

### Gaya & Desain
- **UI:** Menggunakan komponen Material Design 3.
- **Tampilan Pembelian (Lama):** Menggunakan `Card` untuk daftar produk dan FAB untuk akses ke keranjang.

## Rencana Perubahan Saat Ini: Refactor Alur Pembelian & Perbaikan Kritis

### Tujuan
Menyempurnakan alur pembelian secara menyeluruh, mulai dari tampilan hingga logika penyimpanan data, untuk meningkatkan UX dan memperbaiki bug kritis.

### Langkah-langkah Implementasi
1.  **Perbaikan Kritis Struktur Data Firestore (`purchase_service.dart`):**
    *   Mengubah total logika penyimpanan agar sesuai dengan struktur data yang diinginkan pengguna untuk mengatasi error `insufficient permissions`.
    *   **Koleksi `purchase_transactions`:** Menyimpan satu dokumen per transaksi. Dokumen ini akan berisi *array* `items` yang mencakup semua produk yang dibeli.
    *   **Koleksi `purchase_history`:** Membuat satu dokumen terpisah untuk *setiap* item produk dalam transaksi. Dokumen ini akan berisi detail item dan ID transaksi terkait.
    *   Semua operasi (pembuatan transaksi, pembuatan riwayat, dan pembaruan stok produk) akan tetap menggunakan `WriteBatch` untuk menjamin konsistensi data.

2.  **Refactor UI Halaman Pembelian (`purchases_screen.dart`):**
    *   Menghapus seluruh sistem paginasi (halaman) untuk menampilkan semua hasil pencarian dalam satu daftar yang bisa di-*scroll*.

3.  **Refactor UI Halaman Keranjang (`purchase_cart_screen.dart`):**
    *   Mengubah tampilan daftar item di keranjang agar mirip dengan daftar produk di halaman manajemen produk (menggunakan `ListTile` atau `Card` yang informatif).
    *   Menghapus tombol-tombol edit (+, -) yang ada di baris item.
    *   Menerapkan fungsionalitas di mana mengetuk (tap) pada sebuah item di keranjang akan memunculkan dialog `EditPurchaseCartItemDialog` untuk mengubah jumlah atau harga.
