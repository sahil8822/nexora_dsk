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
    private var sensorTypes: List<Int> = listOf(Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_GYROSCOPE)
    private var emitCalibration = false

    private var lastUpdate: Long = 0
    private var throttleIntervalMs: Long = 16 // Default ~60Hz

    private var lastAccX = 0f
    private var lastAccY = 0f
    private var lastAccZ = 0f
    private var lastGyroX = 0f
    private var lastGyroY = 0f
    private var lastGyroZ = 0f
    private var lastTimestampNanos: Long = 0

    companion object {
        init {
            try {
                System.loadLibrary("nexora_core")
            } catch (e: UnsatisfiedLinkError) {
                // Ignore if library not built (mock environment)
            }
        }
    }

    private external fun updateImuFilter(
        ax: Double, ay: Double, az: Double,
        gx: Double, gy: Double, gz: Double,
        dt: Double
    )

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        if (sensorTypes.none { sensorManager.getDefaultSensor(it) != null } && sink != null) {
            sink.error("HARDWARE_UNAVAILABLE", "Sensor not found on this device", null)
        }
    }

    fun configure(options: Map<String, Any?>) {
        @Suppress("UNCHECKED_CAST")
        val names = options["sensorTypes"] as? List<String> ?: listOf("accelerometer", "gyroscope")
        sensorTypes = names.mapNotNull { sensorTypeForName(it) }.ifEmpty {
            listOf(Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_GYROSCOPE)
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
        if (event == null) return

        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            lastAccX = event.values[0]
            lastAccY = event.values[1]
            lastAccZ = event.values[2]
        } else if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
            lastGyroX = event.values[0]
            lastGyroY = event.values[1]
            lastGyroZ = event.values[2]
        }

        if (lastTimestampNanos > 0) {
            val dt = (event.timestamp - lastTimestampNanos) * 1e-9
            if (dt > 0.0 && dt < 1.0) {
                try {
                    updateImuFilter(
                        lastAccX.toDouble(), lastAccY.toDouble(), lastAccZ.toDouble(),
                        lastGyroX.toDouble(), lastGyroY.toDouble(), lastGyroZ.toDouble(),
                        dt
                    )
                } catch (e: UnsatisfiedLinkError) {
                    // C++ library might not be loaded or method not resolved
                }
            }
        }
        lastTimestampNanos = event.timestamp

        val currentTime = System.currentTimeMillis()
        if (currentTime - lastUpdate < throttleIntervalMs) return
        lastUpdate = currentTime

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
