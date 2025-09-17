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
*   **Laporan Penjualan**: Menghasilkan laporan penjualan dalam rentang tanggal, dengan perbaikan bug kritis untuk memastikan keandalan.
*   **Validasi Pesanan (POS)**: Alur kerja pemindaian barcode untuk memvalidasi produk dalam pesanan, dengan penanganan error yang ditingkatkan (tidak kembali halaman saat SKU tidak ditemukan dan memainkan suara error).

## Rencana Saat Ini: Penyelesaian Pesanan Otomatis

**Tujuan**: Mengotomatiskan alur kerja pesanan dengan mengubah status pesanan dari "Dikirim" (`Delivered`) menjadi "Selesai" (`Shipped`) secara otomatis setelah jangka waktu tertentu.

**Logika**: 
1.  Ketika status pesanan diubah menjadi `Delivered` oleh admin, sebuah timestamp `deliveredAt` akan dicatat di dokumen pesanan tersebut.
2.  Sebuah fungsi server (Cloud Function) akan berjalan secara terjadwal (misalnya, setiap hari).
3.  Fungsi ini akan mencari semua pesanan dengan status `Delivered` yang timestamp `deliveredAt`-nya sudah lebih dari 3 hari.
4.  Untuk setiap pesanan yang cocok, fungsi akan secara otomatis memperbarui statusnya menjadi `Shipped`.

**Arsitektur**: 
*   **Aplikasi Flutter (Frontend)**: Bertanggung jawab untuk menambahkan timestamp `deliveredAt` saat pesanan ditandai sebagai `Delivered`.
*   **Cloud Functions (Backend)**: Bertanggung jawab untuk logika penjadwalan dan pembaruan status otomatis.

**Langkah Implementasi**:
1.  **Frontend**: Identifikasi dan modifikasi logika di aplikasi Flutter (kemungkinan besar di `order_provider.dart` atau `order_service.dart`) untuk menambahkan field `deliveredAt: FieldValue.serverTimestamp()` saat memperbarui status ke `Delivered`.
2.  **Backend**: 
    *   Buat direktori `functions` di root proyek.
    *   Buat file `functions/package.json` untuk mendefinisikan dependensi Node.js (`firebase-functions`, `firebase-admin`).
    *   Buat file `functions/index.js` yang berisi kode untuk fungsi terjadwal yang akan memeriksa dan memperbarui status pesanan.
3.  **Deployment**: Memberikan instruksi kepada pengguna untuk men-deploy Cloud Function menggunakan Firebase CLI.
