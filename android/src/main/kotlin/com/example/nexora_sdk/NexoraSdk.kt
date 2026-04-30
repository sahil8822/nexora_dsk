package com.example.nexora_sdk

import io.flutter.plugin.common.PluginRegistry
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import android.app.Activity

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

/**
 * Main Android Plugin Entry Point.
 * Orchestrates multi-hardware subsystems with Activity awareness for permissions.
 */
class NexoraSdk: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var permissionResult: Result? = null
  
  private lateinit var sensorManager: HardwareSensorManager
  private lateinit var cameraManager: HardwareCameraManager
  private lateinit var bluetoothManager: HardwareBluetoothManager
  private lateinit var locationManager: HardwareLocationManager
  
  private var streamHandler: HardwareStreamHandler? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val context = flutterPluginBinding.applicationContext
    this.context = context
    
    // Initialize Subsystems
    sensorManager = HardwareSensorManager(context)
    cameraManager = HardwareCameraManager(context)
    bluetoothManager = HardwareBluetoothManager(context)
    locationManager = HardwareLocationManager(context)

    // Setup Method Channel
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/methods")
    methodChannel.setMethodCallHandler(this)

    // Setup Unified Event Channel
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/events")
    streamHandler = HardwareStreamHandler(context, sensorManager, cameraManager, bluetoothManager, locationManager)
    eventChannel.setStreamHandler(streamHandler)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      // Camera
      "startCamera" -> {
        val width = call.argument<Int>("width") ?: 640
        val height = call.argument<Int>("height") ?: 480
        cameraManager.start(width, height)
        result.success(true)
      }
      "stopCamera" -> {
        cameraManager.stop()
        result.success(true)
      }
      
      // Bluetooth
      "startBluetoothScan" -> {
        HardwareForegroundService.start(context)
        bluetoothManager.startScan()
        result.success(true)
      }
      "stopBluetoothScan" -> {
        bluetoothManager.stopScan()
        result.success(true)
      }
      "connectDevice" -> {
        val deviceId = call.argument<String>("id")
        if (deviceId != null) {
          bluetoothManager.connect(deviceId)
          result.success(true)
        } else {
          result.error("INVALID_ARGUMENT", "Device ID is null", null)
        }
      }
      
      // Location
      "startLocation" -> {
        HardwareForegroundService.start(context)
        locationManager.startUpdates()
        result.success(true)
      }
      "stopLocation" -> {
        locationManager.stopUpdates()
        result.success(true)
      }

      // Sensors
      "startSensor" -> {
        val frequency = call.argument<Int>("frequency") ?: 60
        sensorManager.start(frequency)
        result.success(true)
      }
      "stopSensor" -> {
        sensorManager.stop()
        result.success(true)
      }

      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }

      "requestPermissions" -> {
        requestPermissions(result)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  // --- Permission Handling ---

  private fun requestPermissions(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is null", null)
      return
    }
    this.permissionResult = result
    val permissions = arrayOf(
      Manifest.permission.CAMERA,
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.BLUETOOTH_SCAN,
      Manifest.permission.BLUETOOTH_CONNECT
    )
    ActivityCompat.requestPermissions(activity!!, permissions, 101)
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode == 101) {
      val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      permissionResult?.success(granted)
      permissionResult = null
      return true
    }
    return false
  }

  // --- Activity Lifecycle ---

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    this.activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    this.activity = null
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
