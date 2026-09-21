package io.github.t4toh.contadordetruco

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Lado nativo del updater: DownloadManager, permiso de instalación y el
 * intent del instalador. Sin FileProvider: DownloadManager ya es un
 * content provider y el instalador puede leer de su URI.
 */
class UpdaterPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CANAL = "io.github.t4toh.contadordetruco/updater"
        private const val ARCHIVO = "update.apk"
        private const val MIME_APK = "application/vnd.android.package-archive"
    }

    private val downloadManager
        get() = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "currentVersionName" -> result.success(
                context.packageManager.getPackageInfo(context.packageName, 0).versionName
            )

            "canRequestInstall" -> result.success(
                // Antes de API 26 el permiso de "orígenes desconocidos" es
                // global y lo pide el propio instalador.
                Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                    context.packageManager.canRequestPackageInstalls()
            )

            "openInstallSettings" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:${context.packageName}")
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                }
                result.success(null)
            }

            "enqueueDownload" -> {
                val url = call.argument<String>("url")!!
                // DownloadManager falla con ERROR_FILE_ALREADY_EXISTS si el
                // destino existe (una descarga anterior que no se instaló).
                File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), ARCHIVO).delete()
                val request = DownloadManager.Request(Uri.parse(url))
                    .setTitle("Contador de Truco")
                    .setDescription("Descargando la actualización")
                    .setMimeType(MIME_APK)
                    .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                    .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, ARCHIVO)
                result.success(downloadManager.enqueue(request))
            }

            "queryDownload" -> {
                val id = call.argument<Number>("id")!!.toLong()
                downloadManager.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
                    if (!cursor.moveToFirst()) {
                        // La descarga desapareció (la canceló el usuario desde
                        // la notificación, o el sistema la limpió).
                        result.success(mapOf("status" to "failed", "bytesSoFar" to 0L, "bytesTotal" to 0L))
                        return
                    }
                    val status = when (cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))) {
                        DownloadManager.STATUS_PENDING -> "pending"
                        DownloadManager.STATUS_RUNNING -> "running"
                        DownloadManager.STATUS_PAUSED -> "paused"
                        DownloadManager.STATUS_SUCCESSFUL -> "successful"
                        else -> "failed"
                    }
                    result.success(
                        mapOf(
                            "status" to status,
                            "bytesSoFar" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)),
                            "bytesTotal" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)),
                        )
                    )
                }
            }

            "verifyAndInstall" -> {
                val id = call.argument<Number>("id")!!.toLong()
                val esperado = call.argument<String>("sha256")!!.lowercase()
                val principal = Handler(Looper.getMainLooper())
                // El hash de un APK de ~50 MB tarda; fuera del hilo de UI.
                Thread {
                    var ok = false
                    try {
                        val uri = downloadManager.getUriForDownloadedFile(id)
                        ok = uri != null && sha256(uri) == esperado
                        if (ok) {
                            context.startActivity(
                                Intent(Intent.ACTION_VIEW)
                                    .setDataAndType(uri, MIME_APK)
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                        } else {
                            // Borra el archivo y el registro: no se instala nada corrupto.
                            downloadManager.remove(id)
                        }
                    } catch (e: Exception) {
                        // Sin instalador que abra el APK, o cualquier otra falla: no se instala nada.
                        ok = false
                        runCatching { downloadManager.remove(id) }
                    } finally {
                        principal.post { result.success(ok) }
                    }
                }.start()
            }

            else -> result.notImplemented()
        }
    }

    private fun sha256(uri: Uri): String {
        val digest = MessageDigest.getInstance("SHA-256")
        context.contentResolver.openInputStream(uri)!!.use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val leidos = input.read(buffer)
                if (leidos < 0) break
                digest.update(buffer, 0, leidos)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
}
