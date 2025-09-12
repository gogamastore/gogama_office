# Blueprint Proyek: Aplikasi Manajemen Inventaris & Pesanan

Dokumen ini adalah sumber kebenaran tunggal untuk gaya, desain, dan fitur aplikasi. Dokumen ini diperbarui secara otomatis setelah setiap perubahan.

---

## 1. Ringkasan & Tujuan Aplikasi

Aplikasi ini adalah sistem manajemen inventaris dan pesanan yang komprehensif, dibangun menggunakan Flutter dan Riverpod. Tujuannya adalah untuk menyediakan alat yang mudah digunakan bagi pemilik bisnis untuk melacak produk, mengelola stok, memproses pesanan penjualan, dan mencatat pembelian dari pemasok.

---

## 2. Fitur, Desain, & Arsitektur yang Telah Diimplementasikan

### A. Arsitektur & Teknologi
- **Framework**: Flutter
- **Perender Web**: Dikonfigurasi untuk menggunakan **CanvasKit** di `web/index.html` untuk rendering ikon dan *font* yang andal.
- **Konfigurasi Web**: Jalur dasar (`base href`) diatur secara eksplisit ke `/` di `web/index.html` untuk mencegah *error* 404 saat memuat aset.
- **Manajemen State**: `flutter_riverpod` untuk manajemen state yang reaktif dan terukur.
- **Struktur Proyek**: Kode diorganisir berdasarkan fitur (misalnya, `screens/products`, `screens/orders`).
- **Desain & Tema**: Menggunakan `ThemeData` terpusat di `lib/main.dart` untuk konsistensi visual.

### B. Fitur Utama

- **Manajemen Produk**: Tampilan daftar, pencarian, dan halaman detail produk yang terpusat.
- **Manajemen Pesanan**: Tampilan daftar, detail, dan halaman edit pesanan layar penuh.
- **Manajemen Pembelian**: Alur untuk membuat catatan pembelian baru dan antarmuka keranjang.

### C. Desain & UI/UX

- **Gaya Desain**: Dikelola oleh `ThemeData` terpusat, mengadopsi gaya modern dan bersih.
- **Ikonografi**: Menggunakan paket `ionicons`.
- **Tipografi**: Menggunakan `google_fonts` dengan *font* **Inter**.
- **Palet Warna**: Skema warna terpusat dengan biru (`#5DADE2`) sebagai aksen utama.
- **Gaya Komponen**: Gaya global untuk `AppBar`, `Card`, dan `TextField`.

---

## 3. Rencana & Langkah Perubahan Terbaru

Berikut adalah log dari perubahan terakhir yang diminta dan berhasil diimplementasikan.

### Peningkatan Alur Kerja Halaman Pembelian: Harga Beli Terakhir & Interaksi Intuitif (Saat Ini)

**Tujuan**: Merombak alur kerja pada halaman "Buat Pembelian Baru" agar lebih intuitif. Tombol "Tambah" akan dihapus dan digantikan dengan gestur klik pada seluruh baris produk untuk membuka dialog. Selain itu, harga beli terakhir akan ditampilkan dan digunakan sebagai nilai default untuk mempercepat proses input.

**Langkah-Langkah Eksekusi:**

1.  **Pembaruan Model Produk**: Menambahkan field `lastPurchasePrice` ke model `Product`.
2.  **Modifikasi Logika Proses Pembelian**: Memperbarui logika di `process_purchase_screen.dart` untuk menyimpan harga beli baru ke `lastPurchasePrice` setelah pembelian berhasil.
3.  **Pembaruan UI Halaman Pembelian**: Merombak `purchases_screen.dart` untuk menghapus tombol "Tambah", membuat seluruh `ListTile` dapat diklik, dan menampilkan harga beli terakhir di daftar.
4.  **Pembaruan Dialog Tambah Produk**: Memperbarui `add_to_purchase_cart_dialog.dart` untuk secara otomatis mengisi kolom harga dengan `lastPurchasePrice` produk.

### Perombakan Alur Kerja Produk: Halaman Detail & Navigasi

**Tujuan**: Mengganti alur kerja manajemen produk yang lama (menggunakan ikon edit) dengan sistem yang lebih modern di mana pengguna mengklik item daftar untuk menavigasi ke halaman detail produk yang komprehensif.

**Langkah-Langkah Eksekusi:**

1.  **✅ Pembuatan Halaman Detail Produk**: File baru `lib/screens/products/product_detail_screen.dart` dibuat.
2.  **✅ Modifikasi Halaman Daftar Produk**: File `lib/screens/products/products_screen.dart` diperbarui. Ikon "Edit" dihapus dan seluruh kartu produk dibungkus dengan `InkWell`.
3.  **✅ Implementasi Navigasi**: Logika `onTap` ditambahkan untuk menavigasi ke `ProductDetailScreen`.

### Pemeliharaan Kode: Menghapus Impor yang Tidak Digunakan

**Tujuan**: Menjaga kebersihan kode dengan menghilangkan peringatan `unused_import`.

**Langkah-Langkah Eksekusi:**

1.  **✅ Identifikasi & Tindakan**: Menghapus impor yang tidak terpakai di `lib/screens/purchases/process_purchase_screen.dart`.
