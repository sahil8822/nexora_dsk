package com.nexora.sdk

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
    private var eventSink: EventChannel.EventSink? = null
    private var sensorThread: HandlerThread? = null
    private var sensorHandler: Handler? = null
    private var sensorTypes: List<Int> = listOf(Sensor.TYPE_ACCELEROMETER)
    private var emitCalibration = false

    private var lastUpdate: Long = 0
    private var throttleIntervalMs: Long = 16 // Default ~60Hz

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        if (sensorTypes.none { sensorManager.getDefaultSensor(it) != null } && sink != null) {
            sink.error("HARDWARE_UNAVAILABLE", "Accelerometer not found on this device", null)
        }
    }

    fun configure(options: Map<String, Any?>) {
        @Suppress("UNCHECKED_CAST")
        val names = options["sensorTypes"] as? List<String> ?: listOf("accelerometer")
        sensorTypes = names.mapNotNull { sensorTypeForName(it) }.ifEmpty {
            listOf(Sensor.TYPE_ACCELEROMETER)
        }
        emitCalibration = options["emitCalibration"] as? Boolean ?: false
    }

    fun start(frequencyHz: Int = 60) {
        val sensors = sensorTypes.mapNotNull { sensorManager.getDefaultSensor(it) }
        if (sensors.isEmpty()) return
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
        
        sensors.forEach { sensor ->
            sensorManager.registerListener(this, sensor, delay, sensorHandler)
        }
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

        if (event != null) {
            val data = mapOf(
                "module" to "sensor",
                "type" to "data",
                "timestamp" to currentTime,
                "data" to mapOf(
                    "sensorType" to sensorNameForType(event.sensor.type),
                    "x" to event.values[0],
                    "y" to event.values[1],
                    "z" to event.values[2],
                    "accuracy" to if (emitCalibration) event.accuracy else null
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

    private fun sensorTypeForName(name: String): Int? {
        return when (name) {
            "accelerometer" -> Sensor.TYPE_ACCELEROMETER
            "gyroscope" -> Sensor.TYPE_GYROSCOPE
            "magnetometer" -> Sensor.TYPE_MAGNETIC_FIELD
            "barometer" -> Sensor.TYPE_PRESSURE
            "stepCounter" -> Sensor.TYPE_STEP_COUNTER
            "gravity" -> Sensor.TYPE_GRAVITY
            "linearAcceleration" -> Sensor.TYPE_LINEAR_ACCELERATION
            else -> null
        }
    }

    private fun sensorNameForType(type: Int): String {
        return when (type) {
            Sensor.TYPE_ACCELEROMETER -> "accelerometer"
            Sensor.TYPE_GYROSCOPE -> "gyroscope"
            Sensor.TYPE_MAGNETIC_FIELD -> "magnetometer"
            Sensor.TYPE_PRESSURE -> "barometer"
            Sensor.TYPE_STEP_COUNTER -> "stepCounter"
            Sensor.TYPE_GRAVITY -> "gravity"
            Sensor.TYPE_LINEAR_ACCELERATION -> "linearAcceleration"
            else -> "unknown"
        }
    }
}
