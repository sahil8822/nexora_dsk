package com.example.nexora_sdk

import android.content.Context
import io.flutter.plugin.common.EventChannel

/**
 * Unified Stream Hub for all hardware subsystems.
 * Distributes the event sink to managers and manages lifecycle.
 */
class HardwareStreamHandler(
    private val context: Context,
    private val sensorManager: HardwareSensorManager,
    private val cameraManager: HardwareCameraManager,
    private val bluetoothManager: HardwareBluetoothManager,
    private val locationManager: HardwareLocationManager
) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Connect all managers to the unified sink
        sensorManager.setEventSink(events)
        cameraManager.setEventSink(events)
        bluetoothManager.setEventSink(events)
        locationManager.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        sensorManager.setEventSink(null)
        cameraManager.setEventSink(null)
        bluetoothManager.setEventSink(null)
        locationManager.setEventSink(null)
    }
}
