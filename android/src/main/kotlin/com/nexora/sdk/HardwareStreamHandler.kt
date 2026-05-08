package com.nexora.sdk

import android.content.Context
import io.flutter.plugin.common.EventChannel

/**
 * Unified stream handler for all Nexora hardware events.
 * Manages the lifecycle of sinks for sensors, camera, bluetooth, location, and audio.
 */
class HardwareStreamHandler(
    private val context: Context,
    private val sensorManager: HardwareSensorManager,
    private val cameraManager: HardwareCameraManager,
    private val bluetoothManager: HardwareBluetoothManager,
    private val locationManager: HardwareLocationManager,
    private val audioModule: HardwareAudioModule
) : EventChannel.StreamHandler {

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sensorManager.setEventSink(events)
        cameraManager.setEventSink(events)
        bluetoothManager.setEventSink(events)
        locationManager.setEventSink(events)
        audioModule.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.setEventSink(null)
        cameraManager.setEventSink(null)
        bluetoothManager.setEventSink(null)
        locationManager.setEventSink(null)
        audioModule.setEventSink(null)
    }
}
