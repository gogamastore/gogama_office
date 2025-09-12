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

### Perombakan Alur Kerja Produk: Halaman Detail & Navigasi (Terbaru)

**Tujuan**: Mengganti alur kerja manajemen produk yang lama (menggunakan ikon edit) dengan sistem yang lebih modern di mana pengguna mengklik item daftar untuk menavigasi ke halaman detail produk yang komprehensif.

**Langkah-Langkah Eksekusi:**

1.  **✅ Pembuatan Halaman Detail Produk**: File baru `lib/screens/products/product_detail_screen.dart` dibuat. Halaman ini berfungsi sebagai pusat komando untuk satu produk, menampilkan gambar, judul, harga, stok, deskripsi, dan *app bar* dengan menu tindakan ("Edit", "Log", "Hapus").
2.  **✅ Modifikasi Halaman Daftar Produk**: File `lib/screens/products/products_screen.dart` diperbarui. Ikon "Edit" dihapus dari setiap item. Seluruh kartu produk dibungkus dengan `InkWell` untuk menangani navigasi.
3.  **✅ Implementasi Navigasi**: Logika `onTap` ditambahkan untuk memicu `Navigator.push`, mengarahkan pengguna ke `ProductDetailScreen` yang sesuai dan meneruskan objek produk yang dipilih.
4.  **✅ Hasil**: Alur kerja menjadi lebih intuitif, bersih, dan sejalan dengan praktik desain aplikasi modern. Semua tindakan terkait produk kini terpusat di satu layar yang mudah diakses.

### Pemeliharaan Kode: Menghapus Impor yang Tidak Digunakan

**Tujuan**: Menjaga kebersihan kode dengan menghilangkan peringatan `unused_import`.

**Langkah-Langkah Eksekusi:**

1.  **✅ Identifikasi & Tindakan**: Menghapus impor yang tidak terpakai di `lib/screens/purchases/process_purchase_screen.dart`.

### Peningkatan UI/UX Halaman Pembelian

**Tujuan**: Meningkatkan alur kerja dan kebersihan antarmuka pada halaman "Pembelian".

**Langkah-Langkah Eksekusi:**

1.  **✅ Interaksi Produk Diubah**: Tombol "Tambah" dihapus, dan seluruh kartu produk dibuat dapat diklik.
2.  **✅ Posisi Ikon Keranjang Dipindahkan**: `FloatingActionButton` dipindahkan ke kiri untuk mencegah tumpang tindih.

### Perbaikan Bug: Dialog "Tambah Produk" Macet

**Tujuan**: Memperbaiki bug di mana dialog tidak dapat ditutup karena ketidakcocokan tipe data.

**Langkah-Langkah Eksekusi:**

1.  **✅ Solusi**: Memperbaiki `edit_order_screen.dart` agar dapat menerima dan memproses tipe data yang benar dari dialog.

### Sesi Perbaikan Bug Kritis: Aset Web & Ikon Hilang

**Tujuan**: Menyelesaikan masalah `AssetManifest.bin.json not found (404)`.

**Langkah-Langkah Debugging & Solusi:**

1.  **✅ Solusi Kode**: Memaksa penggunaan perender **CanvasKit** dan mengatur **`base href`** di `web/index.html`.
