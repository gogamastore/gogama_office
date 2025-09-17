# Blueprint Aplikasi

## Ikhtisar

Aplikasi ini adalah aplikasi Point of Sale (POS) yang komprehensif untuk platform seluler, yang dirancang untuk membantu pemilik usaha kecil dan menengah mengelola penjualan, inventaris, dan pelanggan mereka secara efisien. Aplikasi ini dibangun di atas Flutter dan Firebase, memastikan kinerja lintas platform yang andal dan sinkronisasi data real-time.

## Desain dan Fitur

### Versi Awal

*   **Autentikasi**: Pengguna dapat masuk menggunakan email dan kata sandi. Firebase Auth digunakan untuk mengelola autentikasi pengguna.
*   **Manajemen Produk**: Pengguna dapat menambahkan, mengedit, dan melihat produk. Setiap produk memiliki nama, deskripsi, harga, dan stok. Data produk disimpan di Cloud Firestore.
*   **Manajemen Pelanggan**: Pengguna dapat menambahkan, mengedit, dan melihat pelanggan. Setiap pelanggan memiliki nama, email, dan nomor telepon. Data pelanggan disimpan di Cloud Firestore.
*   **Pembuatan Pesanan**: Pengguna dapat membuat pesanan baru dengan menambahkan produk dari daftar dan menetapkan pelanggan. Total pesanan dihitung secara otomatis. Pesanan yang dibuat disimpan di Cloud Firestore.
*   **Daftar Pesanan**: Pengguna dapat melihat daftar semua pesanan yang telah dibuat, termasuk detail seperti tanggal, pelanggan, dan status.
*   **Laporan Transaksi Pembelian**: Pengguna dapat melihat laporan transaksi pembelian dalam rentang tanggal yang dipilih, dengan metrik utama, grafik tren, dan tabel transaksi yang dapat diklik untuk melihat detail faktur.

### Perubahan Saat Ini: Penyempurnaan Dialog Faktur Penjualan

*   **Provider Gambar Produk**: Membuat `lib/providers/product_images_provider.dart` untuk mengambil dan menyediakan URL gambar produk secara efisien ke seluruh aplikasi.
*   **Dialog Faktur yang Ditingkatkan**: Merombak total dialog faktur di `lib/screens/reports/sales_report_screen.dart`.
    *   **Menampilkan Gambar Produk**: Mengintegrasikan `productImagesProvider` untuk menampilkan gambar di samping setiap produk dalam rincian faktur.
    *   **Tabel yang Dapat Digeser**: Membungkus tabel rincian dengan `SingleChildScrollView` untuk memungkinkan pengguliran horizontal, meningkatkan kegunaan pada layar yang lebih kecil.
*   **Pengurutan Pesanan**: Memastikan pesanan dalam laporan diurutkan dari yang terbaru ke yang terlama.
*   **Tata Letak Metrik yang Dioptimalkan**: Memprioritaskan metrik finansial utama di bagian atas halaman laporan.
*   **Perbaikan Bug Kritis**: Menyelesaikan semua masalah tata letak dan error kompilasi sebelumnya.

## Rencana Saat Ini: Selesai

Semua perubahan yang diminta telah diimplementasikan. Dialog faktur penjualan sekarang setara dengan dialog faktur pembelian, menampilkan gambar produk dan dapat digeser, memberikan pengalaman pengguna yang konsisten dan lebih baik.
