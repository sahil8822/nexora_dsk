package com.example.my_hardware_plugin

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

/**
 * Main Android Plugin Entry Point.
 * Orchestrates multi-hardware subsystems.
 */
class MyHardwarePlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  
  private lateinit var sensorManager: HardwareSensorManager
  private lateinit var cameraManager: HardwareCameraManager
  private lateinit var bluetoothManager: HardwareBluetoothManager
  private lateinit var locationManager: HardwareLocationManager
  
  private var streamHandler: HardwareStreamHandler? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val context = flutterPluginBinding.applicationContext
    
    // Initialize Subsystems
    sensorManager = HardwareSensorManager(context)
    cameraManager = HardwareCameraManager(context)
    bluetoothManager = HardwareBluetoothManager(context)
    locationManager = HardwareLocationManager(context)

    // Setup Method Channel
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "my_hardware_plugin/methods")
    methodChannel.setMethodCallHandler(this)

    // Setup Unified Event Channel
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "my_hardware_plugin/events")
    streamHandler = HardwareStreamHandler(context, sensorManager, cameraManager, bluetoothManager, locationManager)
    eventChannel.setStreamHandler(streamHandler)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      // Camera
      "startCamera" -> {
        cameraManager.start()
        result.success(true)
      }
      "stopCamera" -> {
        cameraManager.stop()
        result.success(true)
      }
      
      // Bluetooth
      "startBluetoothScan" -> {
        bluetoothManager.startScan()
        result.success(true)
      }
      "stopBluetoothScan" -> {
        bluetoothManager.stopScan()
        result.success(true)
      }
      
      // Location
      "startLocation" -> {
        locationManager.startUpdates()
        result.success(true)
      }
      "stopLocation" -> {
        locationManager.stopUpdates()
        result.success(true)
      }
      
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    
    // Cleanup Subsystems
    sensorManager.stop()
    cameraManager.stop()
    bluetoothManager.stopScan()
    locationManager.stopUpdates()
  }
}
