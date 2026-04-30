package com.example.nexora_sdk

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.HandlerThread
import io.flutter.plugin.common.EventChannel

/**
 * Hardware Sensor Manager for Accelerometer.
 */
class HardwareSensorManager(private val context: Context) : SensorEventListener {
    private val sensorManager: SensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private var eventSink: EventChannel.EventSink? = null
    private var sensorThread: HandlerThread? = null
    private var sensorHandler: Handler? = null

    private var lastUpdate: Long = 0
    private var throttleIntervalMs: Long = 16 // Default ~60Hz

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        if (accelerometer == null && sink != null) {
            sink.error("HARDWARE_UNAVAILABLE", "Accelerometer not found on this device", null)
        }
    }

    fun start(frequencyHz: Int = 60) {
        if (accelerometer == null) return
        if (sensorThread != null) return // Already running

        this.throttleIntervalMs = (1000 / frequencyHz).toLong()
        
        sensorThread = HandlerThread("SensorThread").apply { start() }
        sensorHandler = Handler(sensorThread!!.looper)
        
        // Map Hz to Android SensorManager delay constants
        val delay = when {
            frequencyHz >= 100 -> SensorManager.SENSOR_DELAY_FASTEST
            frequencyHz >= 60 -> SensorManager.SENSOR_DELAY_UI
            else -> SensorManager.SENSOR_DELAY_NORMAL
        }
        
        sensorManager.registerListener(this, accelerometer, delay, sensorHandler)
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        sensorThread?.quitSafely()
        sensorThread = null
        sensorHandler = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastUpdate < throttleIntervalMs) return
        lastUpdate = currentTime

        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val data = mapOf(
                "type" to "sensor",
                "timestamp" to currentTime,
                "data" to mapOf(
                    "x" to event.values[0],
                    "y" to event.values[1],
                    "z" to event.values[2]
                )
            )
            // Batch to main thread only when needed
            Handler(context.mainLooper).post { 
                try {
                    eventSink?.success(data)
                } catch (e: Exception) {
                    // Sink might be closed
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
