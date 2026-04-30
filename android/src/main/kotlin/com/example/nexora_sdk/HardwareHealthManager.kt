package com.example.nexora_sdk

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
 * Advanced Hardware Health and Automated Logging Manager.
 */
class HardwareHealthManager(private val context: Context) {
    private var isLogging = false
    private var logFile: File? = null
    private var logHandler: Handler? = null
    private var logIntervalMs: Long = 1000

    private val logRunnable = object : Runnable {
        override fun run() {
            if (!isLogging) return
            writeLogEntry()
            logHandler?.postDelayed(this, logIntervalMs)
        }
    }

    fun startLogging(fileName: String, intervalMs: Long) {
        if (isLogging) return
        this.logIntervalMs = intervalMs
        this.logFile = File(context.filesDir, fileName)
        
        if (!logFile!!.exists()) {
            val header = "Timestamp,BatteryLevel,Charging,Temperature,SSID,RSSI\n"
            logFile!!.writeText(header)
        }

        isLogging = true
        logHandler = Handler(Looper.getMainLooper())
        logHandler?.post(logRunnable)
    }

    fun stopLogging() {
        isLogging = false
        logHandler?.removeCallbacks(logRunnable)
    }

    private fun writeLogEntry() {
        val battery = getBatteryInfo()
        val wifi = getWifiInfo()
        val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
        val entry = "$time,${battery["level"]},${battery["isCharging"]},${battery["temperature"]},${wifi?.get("ssid")},${wifi?.get("signalStrength")}\n"
        try {
            FileOutputStream(logFile, true).use { it.write(entry.toByteArray()) }
        } catch (e: Exception) {}
    }

    fun getBatteryInfo(): Map<String, Any> {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus: Intent? = context.registerReceiver(null, filter)
        val level = batteryStatus?.let { intent ->
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            level / scale.toDouble()
        } ?: 0.0
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        val statusString = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            else -> "unknown"
        }
        val temp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return mapOf("level" to level, "isCharging" to isCharging, "status" to statusString, "temperature" to temp / 10.0)
    }

    fun getWifiInfo(): Map<String, Any>? {
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val info = wifiManager.connectionInfo ?: return null
        return mapOf(
            "ssid" to (info.ssid ?: "Unknown"),
            "bssid" to (info.bssid ?: "Unknown"),
            "signalStrength" to info.rssi,
            "ipAddress" to String.format("%d.%d.%d.%d", (info.ipAddress and 0xff), (info.ipAddress shr 8 and 0xff), (info.ipAddress shr 16 and 0xff), (info.ipAddress shr 24 and 0xff))
        )
    }
}
