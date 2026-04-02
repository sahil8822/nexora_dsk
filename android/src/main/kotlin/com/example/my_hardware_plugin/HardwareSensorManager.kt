package com.example.my_hardware_plugin

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

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun start() {
        if (accelerometer == null) return
        sensorThread = HandlerThread("SensorThread").apply { start() }
        sensorHandler = Handler(sensorThread!!.looper)
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI, sensorHandler)
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        sensorThread?.quitSafely()
        sensorThread = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val data = mapOf(
                "type" to "sensor",
                "timestamp" to System.currentTimeMillis(),
                "data" to mapOf(
                    "x" to event.values[0],
                    "y" to event.values[1],
                    "z" to event.values[2]
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(data) }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
