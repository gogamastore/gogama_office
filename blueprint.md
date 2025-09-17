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

### Fitur Sebelumnya: Rombak Tabel Laporan Penjualan

*   **Filter Status Pesanan**: Memastikan laporan penjualan hanya menampilkan pesanan dengan status `Processing`, `Shipped`, dan `Delivered`.
*   **Tabel Transaksi yang Ditingkatkan**: Merombak tabel utama di `lib/screens/reports/sales_report_screen.dart`.
*   **Penyelesaian Bug Kritis**: Memperbaiki serangkaian bug pada logika pembuatan laporan penjualan, termasuk penanganan error untuk status huruf besar/kecil, batasan 30 item pada kueri `whereIn`, dan kesalahan tipe data `String?` vs `String`.

## Rencana Saat Ini: Perbaikan Alur Error Pemindaian Barcode

**Tujuan**: Meningkatkan pengalaman pengguna di halaman validasi pesanan saat SKU produk yang dipindai tidak ditemukan.

**Perilaku Salah Saat Ini**:
Ketika SKU produk yang dipindai tidak ditemukan di database, aplikasi secara otomatis kembali ke halaman sebelumnya, yang mengganggu alur kerja pengguna.

**Perilaku yang Diinginkan**:
1.  **Tetap di Halaman**: Aplikasi harus tetap berada di halaman validasi pesanan.
2.  **Tampilkan Pesan Error**: Sebuah pesan yang jelas (misalnya, "Produk tidak ditemukan") harus ditampilkan kepada pengguna, idealnya menggunakan `SnackBar`.
3.  **Mainkan Efek Suara**: Aplikasi harus memainkan efek suara `error.mp3` yang sudah ada di dalam proyek untuk memberikan umpan balik auditori yang jelas.

**Langkah Implementasi**:
1.  Tambahkan dependensi `audioplayers` untuk fungsionalitas audio.
2.  Pastikan aset suara `assets/sounds/error.mp3` terdaftar dengan benar di `pubspec.yaml`.
3.  Identifikasi logika penanganan pemindaian di layar validasi pesanan.
4.  Modifikasi blok `catch` atau alur penanganan error untuk mencegah navigasi kembali (`Navigator.pop`).
5.  Implementasikan pemutaran suara `error.mp3` dan tampilkan `SnackBar` saat error terjadi.
