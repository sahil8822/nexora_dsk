package com.nexora.sdk

import android.content.Context
import android.os.StatFs
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Lightweight Storage Manager.
 * Provides safe file I/O, secure KeyStore encryption, storage info, and directory access.
 */
class HardwareStorageManager(private val context: Context) {

    private val KEY_ALIAS = "nexora_secure_storage_key"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existingKey = keyStore.getKey(KEY_ALIAS, null) as? SecretKey
        if (existingKey != null) return existingKey

        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build()
        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    fun writeSecureFile(fileName: String, content: String): Boolean {
        return try {
            val key = getOrCreateKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, key)
            
            val iv = cipher.iv
            val encryptedBytes = cipher.doFinal(content.toByteArray(Charsets.UTF_8))
            
            val file = safeFile(fileName)
            FileOutputStream(file).use { fos ->
                fos.write(iv.size)
                fos.write(iv)
                fos.write(encryptedBytes)
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun readSecureFile(fileName: String): String? {
        return try {
            val file = safeFile(fileName)
            if (!file.exists()) return null
            
            val bytes = file.readBytes()
            if (bytes.isEmpty()) return null
            
            val ivSize = bytes[0].toInt()
            val iv = bytes.sliceArray(1..ivSize)
            val encryptedBytes = bytes.sliceArray((ivSize + 1) until bytes.size)
            
            val key = getOrCreateKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val spec = GCMParameterSpec(128, iv)
            cipher.init(Cipher.DECRYPT_MODE, key, spec)
            
            val decryptedBytes = cipher.doFinal(encryptedBytes)
            String(decryptedBytes, Charsets.UTF_8)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun deleteSecureFile(fileName: String): Boolean {
        return deleteFile(fileName)
    }

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

    /// Appends text content to a file inside app-private storage.
    fun appendFile(fileName: String, content: String): String {
        val file = safeFile(fileName)
        FileOutputStream(file, true).use { it.write(content.toByteArray()) }
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
    
    fun saveToGallery(filePath: String, callback: (String?) -> Unit) {
        val file = File(filePath)
        if (!file.exists()) {
            callback(null)
            return
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, if (file.name.endsWith(".mp4")) "video/mp4" else "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, if (file.name.endsWith(".mp4")) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val collection = if (file.name.endsWith(".mp4")) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            }
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
        }

        val uri = context.contentResolver.insert(collection, values)
        if (uri != null) {
            try {
                context.contentResolver.openOutputStream(uri)?.use { out ->
                    FileInputStream(file).use { input ->
                        input.copyTo(out)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    values.clear()
                    values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                    context.contentResolver.update(uri, values, null, null)
                }
                callback(uri.toString())
            } catch (e: Exception) {
                context.contentResolver.delete(uri, null, null)
                callback(null)
            }
        } else {
            callback(null)
        }
    }

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
