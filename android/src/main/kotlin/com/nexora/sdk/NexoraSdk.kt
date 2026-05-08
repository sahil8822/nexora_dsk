package com.nexora.sdk

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry

/**
 * Nexora SDK v3.1.2 — Complete Native Plugin with Storage.
 */
class NexoraSdk: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val PERMISSION_REQUEST_CODE = 7310
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null
    private var pendingPermissionType: String? = null
    private var textureRegistry: TextureRegistry? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    private lateinit var camera: HardwareCameraManager
    private lateinit var audio: HardwareAudioModule
    private lateinit var sensors: HardwareSensorManager
    private lateinit var bluetooth: HardwareBluetoothManager
    private lateinit var location: HardwareLocationManager
    private lateinit var biometrics: HardwareBiometricManager
    private lateinit var feedback: HardwareFeedbackManager
    private lateinit var health: HardwareHealthManager
    private lateinit var storage: HardwareStorageManager

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        textureRegistry = flutterPluginBinding.textureRegistry
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/methods")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/events")
        
        camera = HardwareCameraManager(context)
        audio = HardwareAudioModule(context)
        sensors = HardwareSensorManager(context)
        bluetooth = HardwareBluetoothManager(context)
        location = HardwareLocationManager(context)
        biometrics = HardwareBiometricManager(context)
        feedback = HardwareFeedbackManager(context)
        health = HardwareHealthManager(context)
        storage = HardwareStorageManager(context)

        val handler = HardwareStreamHandler(context, sensors, camera, bluetooth, location, audio)
        eventChannel.setStreamHandler(handler)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            handleMethodCallSafe(call, result)
        } catch (e: Exception) {
            result.error("NEXORA_ERROR", e.message ?: "Unknown error", e.stackTraceToString())
        }
    }

    private fun handleMethodCallSafe(call: MethodCall, result: Result) {
        when (call.method) {
            // ==================== Camera & Vision ====================
            "startCamera" -> {
                if (!hasPermission(Manifest.permission.CAMERA)) {
                    result.error("PERMISSION_DENIED", "Camera permission is required.", null)
                    return
                }
                val width = call.argument<Int>("width") ?: 1280
                val height = call.argument<Int>("height") ?: 720
                textureEntry = textureRegistry?.createSurfaceTexture()
                val entry = textureEntry
                if (entry == null) {
                    result.error("CAMERA_ERROR", "Texture registry is unavailable.", null)
                    return
                }
                entry.surfaceTexture().setDefaultBufferSize(width, height)
                val surface = android.view.Surface(entry.surfaceTexture())
                camera.startWithSurface(surface, width, height)
                result.success(entry.id())
            }
            "stopCamera" -> {
                camera.stop()
                textureEntry?.release()
                textureEntry = null
                result.success(true)
            }
            "setVisionMode" -> {
                camera.setVisionMode(
                    call.argument<Boolean>("face") ?: false,
                    call.argument<Boolean>("barcode") ?: false
                )
                result.success(true)
            }
            "setFlash" -> {
                camera.setFlash(call.argument<Boolean>("on") ?: false)
                result.success(true)
            }
            "setZoom" -> {
                camera.setZoom((call.argument<Double>("level") ?: 1.0).toFloat())
                result.success(true)
            }
            "flipCamera" -> {
                camera.flipCamera()
                result.success(true)
            }

            // ==================== Audio & FFT ====================
            "startAudio" -> {
                if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
                    result.error("PERMISSION_DENIED", "Microphone permission is required.", null)
                    return
                }
                result.success(
                    audio.start(
                        call.argument<Boolean>("enableFFT") ?: false,
                        call.argument<Boolean>("streamBytes") ?: false,
                        call.argument<Int>("updateIntervalMs") ?: 80
                    )
                )
            }
            "stopAudio" -> { audio.stop(); result.success(true) }

            // ==================== Bluetooth ====================
            "startBluetoothScan" -> {
                if (!hasBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth scan/connect permission is required.", null)
                    return
                }
                result.success(bluetooth.startScan())
            }
            "stopBluetoothScan" -> { result.success(bluetooth.stopScan()) }
            "connectDevice" -> {
                if (!hasBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth connect permission is required.", null)
                    return
                }
                result.success(bluetooth.connect(call.argument<String>("id") ?: ""))
            }
            "discoverServices" -> {
                bluetooth.discoverServices(call.argument<String>("id") ?: "") { services ->
                    result.success(services)
                }
            }
            "sendData" -> {
                result.success(bluetooth.sendData(
                    call.argument<String>("deviceId") ?: "",
                    call.argument<String>("serviceId") ?: "",
                    call.argument<String>("charId") ?: "",
                    (call.argument<List<Int>>("data") ?: emptyList()).map { it.toByte() }.toByteArray()
                ))
            }

            // ==================== Location & Geofencing ====================
            "startLocation" -> {
                if (!hasLocationPermission()) {
                    result.error("PERMISSION_DENIED", "Location permission is required.", null)
                    return
                }
                location.startUpdates()
                result.success(true)
            }
            "stopLocation" -> { location.stopUpdates(); result.success(true) }
            "setBackgroundLocationEnabled" -> {
                location.setBackgroundEnabled(call.argument<Boolean>("enabled") ?: false)
                result.success(true)
            }
            "addGeofence" -> {
                if (!hasLocationPermission()) {
                    result.error("PERMISSION_DENIED", "Location permission is required.", null)
                    return
                }
                val id = call.argument<String>("id")
                val lat = call.argument<Double>("lat")
                val lon = call.argument<Double>("lon")
                val radius = call.argument<Double>("radius")
                if (id.isNullOrBlank() || lat == null || lon == null || radius == null || radius <= 0.0) {
                    result.error("INVALID_ARGUMENT", "Geofence requires id, lat, lon, and a positive radius.", null)
                    return
                }
                val added = location.addGeofence(
                    id,
                    lat,
                    lon,
                    radius.toFloat()
                )
                result.success(added)
            }

            // ==================== Sensors ====================
            "startSensor" -> { sensors.start(call.argument<Int>("frequency") ?: 60); result.success(true) }
            "stopSensor" -> { sensors.stop(); result.success(true) }

            // ==================== Biometrics ====================
            "authenticate" -> {
                val act = activity
                if (act != null) {
                    biometrics.authenticate(act, call.argument<String>("reason") ?: "Authentication Required") { success ->
                        result.success(success)
                    }
                } else {
                    result.error("NO_ACTIVITY", "Biometric authentication requires a foreground activity", null)
                }
            }
            "canAuthenticate" -> result.success(biometrics.canAuthenticate())

            // ==================== Feedback ====================
            "vibrate" -> { feedback.vibrate((call.argument<Int>("duration") ?: 50).toLong()); result.success(null) }
            "hapticFeedback" -> { feedback.haptic(call.argument<String>("type") ?: "impact"); result.success(null) }

            // ==================== Health ====================
            "getBatteryInfo" -> result.success(health.getBatteryInfo())
            "getWifiInfo" -> result.success(health.getWifiInfo())
            "startLogging" -> {
                result.success(
                    health.startLogging(
                        call.argument<String>("fileName") ?: "log.csv",
                        (call.argument<Int>("interval") ?: 1000).toLong()
                    )
                )
            }
            "stopLogging" -> { health.stopLogging(); result.success(true) }

            // ==================== Storage ====================
            "getStorageInfo" -> result.success(storage.getStorageInfo())
            "writeFile" -> {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName == null || content == null) {
                    result.error("INVALID_ARGUMENT", "writeFile requires fileName and content.", null)
                    return
                }
                val path = storage.writeFile(fileName, content)
                result.success(path)
            }
            "readFile" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "readFile requires fileName.", null)
                    return
                }
                result.success(storage.readFile(fileName))
            }
            "deleteFile" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "deleteFile requires fileName.", null)
                    return
                }
                result.success(storage.deleteFile(fileName))
            }
            "fileExists" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "fileExists requires fileName.", null)
                    return
                }
                result.success(storage.fileExists(fileName))
            }
            "listFiles" -> result.success(storage.listFiles())
            "writeBytes" -> {
                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                if (fileName == null || bytes == null) {
                    result.error("INVALID_ARGUMENT", "writeBytes requires fileName and bytes.", null)
                    return
                }
                val path = storage.writeBytes(fileName, bytes)
                result.success(path)
            }
            "readBytes" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "readBytes requires fileName.", null)
                    return
                }
                result.success(storage.readBytes(fileName))
            }
            "clearCache" -> result.success(storage.clearCache())
            "getAppDirectory" -> result.success(storage.getAppDirectory())
            "getCacheDirectory" -> result.success(storage.getCacheDirectory())
            "getExternalDirectory" -> result.success(storage.getExternalDirectory())

            // ==================== Base ====================
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "requestPermissions" -> requestNativePermissions(result)
            "requestPermission" -> requestNativePermission(call.argument<String>("type"), result)
            
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        releaseHardware()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun releaseHardware() {
        try { camera.stop() } catch (_: Exception) {}
        try { audio.stop() } catch (_: Exception) {}
        try { sensors.stop() } catch (_: Exception) {}
        try { location.stopUpdates() } catch (_: Exception) {}
        try { bluetooth.disconnect() } catch (_: Exception) {}
        try { health.stopLogging() } catch (_: Exception) {}
        textureEntry?.release()
        textureEntry = null
    }

    private fun requestNativePermissions(result: Result) {
        val act = activity
        if (act == null) {
            result.success(hasAllCriticalPermissions())
            return
        }

        val missing = criticalRuntimePermissions().filter { !hasPermission(it) }.toTypedArray()
        if (missing.isEmpty()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_REQUEST_IN_PROGRESS", "A permission request is already running.", null)
            return
        }

        pendingPermissionResult = result
        pendingPermissionType = null
        act.requestPermissions(missing, PERMISSION_REQUEST_CODE)
    }

    private fun requestNativePermission(type: String?, result: Result) {
        val permissions = when (type) {
            "camera" -> listOf(Manifest.permission.CAMERA)
            "audio" -> listOf(Manifest.permission.RECORD_AUDIO)
            "location" -> listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
            "bluetooth" -> bluetoothRuntimePermissions()
            else -> {
                result.error("INVALID_ARGUMENT", "Unknown permission type: $type", null)
                return
            }
        }

        val act = activity
        if (act == null) {
            result.success(permissionsSatisfied(type))
            return
        }

        val missing = permissions.filter { !hasPermission(it) }.toTypedArray()
        if (missing.isEmpty()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_REQUEST_IN_PROGRESS", "A permission request is already running.", null)
            return
        }

        pendingPermissionResult = result
        pendingPermissionType = type
        act.requestPermissions(missing, PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        pendingPermissionResult?.success(
            if (pendingPermissionType == null) hasAllCriticalPermissions() else permissionsSatisfied(pendingPermissionType)
        )
        pendingPermissionResult = null
        pendingPermissionType = null
        return true
    }

    private fun criticalRuntimePermissions(): List<String> {
        val permissions = mutableListOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        permissions.addAll(bluetoothRuntimePermissions())
        return permissions
    }

    private fun bluetoothRuntimePermissions(): List<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasLocationPermission(): Boolean {
        return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) || hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    private fun hasBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return hasLocationPermission()
        return hasPermission(Manifest.permission.BLUETOOTH_SCAN) && hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
    }

    private fun permissionsSatisfied(type: String?): Boolean {
        return when (type) {
            "camera" -> hasPermission(Manifest.permission.CAMERA)
            "audio" -> hasPermission(Manifest.permission.RECORD_AUDIO)
            "location" -> hasLocationPermission()
            "bluetooth" -> hasBluetoothPermissions()
            else -> false
        }
    }

    private fun hasAllCriticalPermissions(): Boolean {
        return hasPermission(Manifest.permission.CAMERA) &&
            hasPermission(Manifest.permission.RECORD_AUDIO) &&
            hasLocationPermission() &&
            hasBluetoothPermissions()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }
}
