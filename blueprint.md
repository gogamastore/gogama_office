# Blueprint Aplikasi

## Ikhtisar

Aplikasi ini adalah aplikasi Point of Sale (POS) yang komprehensif untuk platform seluler, yang dirancang untuk membantu pemilik usaha kecil dan menengah mengelola penjualan, inventaris, dan pelanggan mereka secara efisien. Aplikasi ini dibangun di atas Flutter dan Firebase, memastikan kinerja lintas platform yang andal dan sinkronisasi data real-time.

## Desain dan Fitur

### Fitur Utama

*   **Autentikasi**: Pengguna dapat masuk menggunakan email dan kata sandi.
*   **Manajemen Produk**: CRUD (Create, Read, Update, Delete) untuk produk dengan detail seperti nama, SKU, harga, dan stok.
*   **Manajemen Pelanggan**: CRUD untuk data pelanggan.
*   **Pembuatan Pesanan**: Membuat pesanan baru dengan produk dan pelanggan terkait.
*   **Daftar Pesanan**: Melihat daftar pesanan dengan status yang berbeda (`Processing`, `Delivered`, `Shipped`).
*   **Validasi Pesanan (POS)**: Alur kerja pemindaian barcode untuk memvalidasi produk dalam pesanan, dengan penanganan error yang ditingkatkan.
*   **Pusat Laporan Komprehensif**:
    *   Laporan Transaksi Pembelian
    *   Laporan Arus Stok
    *   Laporan Penjualan
    *   Laporan Penjualan Produk
    *   Laporan Piutang Usaha
    *   **Laporan Utang Dagang**: Melacak semua pembelian kredit yang belum lunas. (Fitur Baru)

## Rencana Saat Ini: Laporan Utang Dagang (Selesai)

### Ikhtisar Fitur

Membuat halaman laporan baru untuk menampilkan semua transaksi pembelian yang dilakukan secara kredit dan belum lunas. Laporan ini krusial untuk mengelola kewajiban dan arus kas keluar perusahaan.

### Langkah-langkah Implementasi

1.  **Buat Model `Purchase`**: Model `lib/models/purchase.dart` yang sudah ada digunakan, yang berisi semua detail transaksi pembelian, termasuk `purchaseDate`, `paymentMethod`, dan `totalAmount`.

2.  **Kembangkan `ReportService.generatePayableReport`**: Logika bisnis inti ditambahkan ke `lib/services/report_service.dart`. Fungsi ini dirancang untuk:
    *   Mengambil transaksi dari koleksi `purchase_transactions`.
    *   Memfilter transaksi berdasarkan `paymentMethod` yang merupakan `credit` atau `Credit`.
    *   Memfilter berdasarkan rentang tanggal yang dipilih (`purchaseDate`).
    *   Secara lokal, memfilter data untuk mengecualikan transaksi yang mungkin di masa depan memiliki status `paid`.
    *   Menggunakan constructor `Purchase.fromMap` untuk mengubah data Firestore menjadi objek Dart.
    *   Mengurutkan hasil berdasarkan tanggal pembelian untuk menampilkan utang terlama di bagian atas.

3.  **Buat Halaman `PayableReportScreen`**: File `lib/screens/reports/payable_report_screen.dart` dibuat sebagai antarmuka pengguna. Halaman ini berisi:
    *   Pemilih rentang tanggal (`DateRangePicker`).
    *   Tombol untuk memicu pembuatan laporan.
    *   Area untuk menampilkan data laporan atau pesan jika tidak ada data.

4.  **Desain Widget `PayableList`**: Widget `lib/widgets/reports/payable_list.dart` dibuat khusus untuk menampilkan data utang dalam `DataTable` yang rapi. Fitur utamanya adalah:
    *   Menampilkan kolom: Tanggal, Supplier, Total, Metode Pembayaran, Status Pembayaran, dan Status Transaksi.
    *   Menggunakan `NumberFormat` untuk menampilkan total dalam format mata uang Rupiah.
    *   Kolom "Status Pembayaran" secara konsisten menampilkan "Kredit" dengan gaya teks tebal berwarna oranye untuk menyorot status utang.
    *   Dibungkus dalam `SingleChildScrollView` horizontal untuk memastikan tabel responsif dan dapat digulir pada layar kecil.

5.  **Integrasikan Navigasi**: Tombol "Laporan Utang Dagang" di halaman "Pusat Laporan" (`lib/screens/profile/reports_screen.dart`) diaktifkan untuk menavigasi pengguna ke `PayableReportScreen` yang baru.

6.  **Buat Indeks Firestore**: Panduan manual diberikan untuk membuat indeks komposit yang diperlukan di koleksi `purchase_transactions` pada field `paymentMethod` (Naik) dan `purchaseDate` (Naik) untuk memastikan kueri berjalan cepat dan efisien.
