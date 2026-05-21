package com.nexora.sdk

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class SmartSyncManager(private val context: Context) {
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var isEnabled = false
    private var uploadUrl: String = ""
    private var headersMap: Map<String, String> = mapOf()
    private var requireWifiConnection = true
    private var rollLimit = 2 * 1024 * 1024

    private val syncDirectory: File by lazy {
        File(context.cacheDir, "smart_sync").apply { if (!exists()) mkdirs() }
    }

    fun enable(url: String, headers: Map<String, String>, limit: Int, wifiOnly: Boolean) {
        uploadUrl = url
        headersMap = headers
        rollLimit = limit
        requireWifiConnection = wifiOnly
        
        if (!isEnabled) {
            isEnabled = true
            startSyncQueue()
        }
    }

    fun queueData(data: String) {
        if (!isEnabled) return
        executor.execute {
            try {
                val activeFile = File(syncDirectory, "active_log.txt")
                if (activeFile.exists() && activeFile.length() >= rollLimit) {
                    val rolledFile = File(syncDirectory, "rolled_${System.currentTimeMillis()}.txt")
                    activeFile.renameTo(rolledFile)
                }
                activeFile.appendText(data + "\n")
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun startSyncQueue() {
        executor.execute {
            var backoffMs = 5000L
            while (isEnabled) {
                try {
                    if (isNetworkAvailable()) {
                        val files = syncDirectory.listFiles { _, name -> name.startsWith("rolled_") }
                        var uploadedAny = false
                        
                        if (files != null && files.isNotEmpty()) {
                            for (file in files.sortedBy { it.name }) {
                                if (uploadFile(file)) {
                                    file.delete()
                                    uploadedAny = true
                                    backoffMs = 5000L
                                } else {
                                    break
                                }
                            }
                        }
                        
                        val activeFile = File(syncDirectory, "active_log.txt")
                        if (activeFile.exists() && activeFile.length() > 0 && !uploadedAny) {
                            val rolledFile = File(syncDirectory, "rolled_${System.currentTimeMillis()}.txt")
                            activeFile.renameTo(rolledFile)
                            continue
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                try {
                    Thread.sleep(backoffMs)
                } catch (e: InterruptedException) {
                    break
                }
                if (backoffMs < 300000L) {
                    backoffMs *= 2
                }
            }
        }
    }

    private fun uploadFile(file: File): Boolean {
        var connection: HttpURLConnection? = null
        return try {
            val content = file.readText()
            val url = URL(uploadUrl)
            connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            for ((key, value) in headersMap) {
                connection.setRequestProperty(key, value)
            }
            if (!headersMap.containsKey("Content-Type")) {
                connection.setRequestProperty("Content-Type", "application/json")
            }

            connection.outputStream.use { os ->
                os.write(content.toByteArray(Charsets.UTF_8))
            }

            val responseCode = connection.responseCode
            responseCode in 200..299
        } catch (e: Exception) {
            e.printStackTrace()
            false
        } finally {
            connection?.disconnect()
        }
    }

    private fun isNetworkAvailable(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(activeNetwork) ?: return false
        
        if (requireWifiConnection) {
            return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        }
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
    }

    fun disable() {
        isEnabled = false
    }
}
