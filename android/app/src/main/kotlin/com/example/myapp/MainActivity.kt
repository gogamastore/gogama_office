package store.gogama.office.gogama_office

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "store.gogama.office/bulk_edit"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "exportExcel") {
                // Tambahkan logika Kotlin Anda di sini untuk menangani ekspor file.
                // Contoh:
                // val dataToExport = // Ambil data dari argumen call jika ada
                // exportFile(dataToExport)
                // result.success("Ekspor berhasil!")

                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}