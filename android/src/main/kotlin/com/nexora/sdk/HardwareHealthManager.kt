package com.nexora.sdk

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

/**
 * Advanced Hardware Health & Diagnostics.
 * Records battery, thermal, and connectivity metrics to CSV.
 */
class HardwareHealthManager(private val context: Context) {
    private var isLogging = false
    private var logFile: File? = null
    private val handler = Handler(Looper.getMainLooper())
    private val logRunnable = object : Runnable {
        override fun run() {
            if (isLogging) {
                writeLogEntry()
                handler.postDelayed(this, logInterval)
            }
        }
    }
    private var logInterval: Long = 1000

    fun getBatteryInfo(): Map<String, Any> {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        
        return mapOf(
            "level" to (level / scale.toFloat() * 100).toInt(),
            "isCharging" to isCharging,
            "temperature" to (temp / 10.0),
            "status" to when(status) {
                BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
                BatteryManager.BATTERY_STATUS_FULL -> "full"
                else -> "unknown"
            }
        )
    }

    fun getWifiInfo(): Map<String, Any>? {
        return try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifiManager.connectionInfo
            mapOf(
                "ssid" to (info.ssid ?: "unknown"),
                "bssid" to (info.bssid ?: "unknown"),
                "signalStrength" to info.rssi,
                "ipAddress" to android.text.format.Formatter.formatIpAddress(info.ipAddress)
            )
        } catch (e: SecurityException) {
            // Permission missing at runtime
            null
        } catch (e: Exception) {
            null
        }
    }

    fun startLogging(fileName: String, intervalMs: Long): Boolean {
        if (!isSafeFileName(fileName)) return false
        this.logInterval = intervalMs
        this.logFile = File(context.filesDir, fileName)
        if (!logFile!!.exists()) {
            logFile!!.writeText("Timestamp,Battery_Level,Is_Charging,Wifi_SSID,Wifi_RSSI\n")
        }
        isLogging = true
        handler.post(logRunnable)
        return true
    }

    private fun writeLogEntry() {
        val battery = getBatteryInfo()
        val wifi = getWifiInfo()
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        val entry = "$timestamp,${battery["level"]},${battery["isCharging"]},${wifi?.get("ssid") ?: "N/A"},${wifi?.get("rssi") ?: "N/A"}\n"
        
        try {
            FileOutputStream(logFile, true).use { it.write(entry.toByteArray()) }
        } catch (e: Exception) {}
    }

    fun stopLogging() {
        isLogging = false
        handler.removeCallbacks(logRunnable)
    }

    private fun isSafeFileName(fileName: String): Boolean {
        return fileName.isNotBlank() &&
            fileName.length <= 120 &&
            !fileName.contains("/") &&
            !fileName.contains("\\") &&
            fileName != "." &&
            fileName != ".."
    }
}
