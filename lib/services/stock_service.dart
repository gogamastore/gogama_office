import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/stock_adjustment_dialog.dart'; // Untuk enum StockAdjustmentType

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<void> adjustStock({
    required String productId,
    required StockAdjustmentType adjustmentType,
    required int quantity,
    required String reason,
  }) async {
    if (quantity <= 0) {
      throw Exception('Jumlah harus lebih dari nol.');
    }

    final productRef = _firestore.collection('products').doc(productId);
    final adjustmentId = _uuid.v4();
    final adjustmentRef = _firestore.collection('stock_adjustments').doc(adjustmentId);

    // Tentukan nilai penambahan/pengurangan stok
    final int stockChange = adjustmentType == StockAdjustmentType.stockIn ? quantity : -quantity;

    // Buat WriteBatch untuk operasi atomik
    final WriteBatch batch = _firestore.batch();

    // 1. Update stok di dokumen produk
    batch.update(productRef, {
      'stock': FieldValue.increment(stockChange),
    });

    // 2. Buat catatan di koleksi stock_adjustments
    batch.set(adjustmentRef, {
      'productId': productId,
      'date': FieldValue.serverTimestamp(),
      'type': adjustmentType == StockAdjustmentType.stockIn ? 'in' : 'out',
      'quantity': quantity,
      'reason': reason,
    });

    // Jalankan batch
    await batch.commit();
  }
}
