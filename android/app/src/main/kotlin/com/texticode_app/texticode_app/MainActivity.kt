package com.texticode_app.texticode_app

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private data class PendingPdf(val bytes: ByteArray, val result: MethodChannel.Result)

    private var pendingPdf: PendingPdf? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "texticode/archivos")
            .setMethodCallHandler { call, result ->
                if (call.method != "guardarPdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("nombre")
                if (bytes == null || filename.isNullOrBlank()) {
                    result.error("argumentos", "Falta el PDF o el nombre del archivo.", null)
                    return@setMethodCallHandler
                }
                if (pendingPdf != null) {
                    result.error("ocupado", "Ya hay una descarga en curso.", null)
                    return@setMethodCallHandler
                }

                pendingPdf = PendingPdf(bytes, result)
                try {
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_TITLE, filename)
                    }
                    startActivityForResult(intent, SAVE_PDF)
                } catch (error: RuntimeException) {
                    pendingPdf = null
                    result.error("selector", "No se pudo abrir el selector de archivos.", null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_PDF) return
        val pdf = pendingPdf ?: return
        pendingPdf = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pdf.result.success(false)
            return
        }

        Thread {
            try {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw IOException("No se pudo abrir el archivo.")
                output.use { it.write(pdf.bytes) }
                runOnUiThread { pdf.result.success(true) }
            } catch (error: Exception) {
                runOnUiThread {
                    pdf.result.error("escritura", "No se pudo guardar el PDF.", null)
                }
            }
        }.start()
    }

    private companion object {
        const val SAVE_PDF = 4201
    }
}
