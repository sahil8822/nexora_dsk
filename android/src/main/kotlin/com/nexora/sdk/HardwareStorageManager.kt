package com.nexora.sdk

import android.content.Context
import android.os.StatFs
import java.io.File
import java.io.FileOutputStream

/**
 * Lightweight Storage Manager.
 * Provides safe file I/O, storage info, and directory access
 * without heavy external dependencies.
 */
class HardwareStorageManager(private val context: Context) {

    /// Returns total & available storage in bytes for internal and external storage.
    fun getStorageInfo(): Map<String, Any> {
        val internal = context.filesDir
        val external = context.getExternalFilesDir(null)
        
        val internalStat = StatFs(internal.absolutePath)
        val internalTotal = internalStat.blockSizeLong * internalStat.blockCountLong
        val internalFree = internalStat.blockSizeLong * internalStat.availableBlocksLong

        var externalTotal = 0L
        var externalFree = 0L
        if (external != null && external.exists()) {
            val externalStat = StatFs(external.absolutePath)
            externalTotal = externalStat.blockSizeLong * externalStat.blockCountLong
            externalFree = externalStat.blockSizeLong * externalStat.availableBlocksLong
        }

        return mapOf(
            "internalTotal" to internalTotal,
            "internalFree" to internalFree,
            "externalTotal" to externalTotal,
            "externalFree" to externalFree,
            "appCacheSize" to getDirSize(context.cacheDir),
            "appDataSize" to getDirSize(context.filesDir)
        )
    }

    /// Writes text content to a file inside app-private storage.
    fun writeFile(fileName: String, content: String): String {
        val file = safeFile(fileName)
        FileOutputStream(file).use { it.write(content.toByteArray()) }
        return file.absolutePath
    }

    /// Reads a text file from app-private storage.
    fun readFile(fileName: String): String? {
        val file = safeFile(fileName)
        if (!file.exists()) return null
        return file.readText()
    }

    /// Deletes a file from app-private storage.
    fun deleteFile(fileName: String): Boolean {
        val file = safeFile(fileName)
        return if (file.exists()) file.delete() else false
    }

    /// Checks whether a file exists in app-private storage.
    fun fileExists(fileName: String): Boolean {
        return safeFile(fileName).exists()
    }

    /// Lists all files in app-private storage directory.
    fun listFiles(): List<Map<String, Any>> {
        val dir = context.filesDir
        val files = dir.listFiles() ?: return emptyList()
        return files.map { f ->
            mapOf(
                "name" to f.name,
                "size" to f.length(),
                "isDirectory" to f.isDirectory,
                "lastModified" to f.lastModified()
            )
        }
    }

    /// Writes raw bytes to a file in app-private storage.
    fun writeBytes(fileName: String, bytes: ByteArray): String {
        val file = safeFile(fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }

    /// Reads raw bytes from a file in app-private storage.
    fun readBytes(fileName: String): ByteArray? {
        val file = safeFile(fileName)
        if (!file.exists()) return null
        return file.readBytes()
    }

    /// Clears the app cache directory.
    fun clearCache(): Boolean {
        return try {
            deleteDir(context.cacheDir)
            true
        } catch (e: Exception) { false }
    }

    /// Returns the absolute path to the app-private files directory.
    fun getAppDirectory(): String = context.filesDir.absolutePath

    /// Returns the absolute path to the app-private cache directory.
    fun getCacheDirectory(): String = context.cacheDir.absolutePath

    /// Returns the external (shared) storage path if available.
    fun getExternalDirectory(): String? = context.getExternalFilesDir(null)?.absolutePath

    // --- Helpers ---

    private fun safeFile(fileName: String): File {
        require(isSafeFileName(fileName)) {
            "File name must be non-empty and cannot contain path separators."
        }
        val baseDir = context.filesDir.canonicalFile
        val file = File(baseDir, fileName).canonicalFile
        require(file.path.startsWith(baseDir.path + File.separator)) {
            "File path must stay inside app-private storage."
        }
        return file
    }

    private fun isSafeFileName(fileName: String): Boolean {
        return fileName.isNotBlank() &&
            fileName.length <= 120 &&
            !fileName.contains("/") &&
            !fileName.contains("\\") &&
            fileName != "." &&
            fileName != ".."
    }

    private fun getDirSize(dir: File): Long {
        if (!dir.exists()) return 0
        var size = 0L
        val files = dir.listFiles()
        if (files != null) {
            for (f in files) {
                size += if (f.isDirectory) getDirSize(f) else f.length()
            }
        }
        return size
    }

    private fun deleteDir(dir: File) {
        val files = dir.listFiles()
        if (files != null) {
            for (f in files) {
                if (f.isDirectory) deleteDir(f) else f.delete()
            }
        }
    }
}
