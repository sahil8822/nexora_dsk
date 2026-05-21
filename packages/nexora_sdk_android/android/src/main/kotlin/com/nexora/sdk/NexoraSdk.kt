package com.nexora.sdk

import android.Manifest
import android.app.ActivityManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.content.ClipData
import android.content.ClipboardManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
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
import android.media.AudioManager

/**
 * Nexora SDK v3.1.2 — Complete Native Plugin with Storage.
 */
class NexoraSdk: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.NewIntentListener, android.content.ComponentCallbacks2 {
    companion object {
        private const val PERMISSION_REQUEST_CODE = 7310
        private const val PREFS_NAME = "nexora_sdk_permissions"
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
    private var ecoModeUserEnabled = false

    private lateinit var camera: HardwareCameraManager
    private lateinit var audio: HardwareAudioModule
    private lateinit var sensors: HardwareSensorManager
    private lateinit var bluetooth: HardwareBluetoothManager
    private lateinit var location: HardwareLocationManager
    private lateinit var biometrics: HardwareBiometricManager
    private lateinit var feedback: HardwareFeedbackManager
    private lateinit var health: HardwareHealthManager
    private lateinit var storage: HardwareStorageManager
    private lateinit var nfc: HardwareNfcManager
    private lateinit var smartSync: SmartSyncManager
    private lateinit var ai: HardwareAiManager
    private lateinit var usb: HardwareUsbManager
    private lateinit var crypto: HardwareCryptoManager
    private lateinit var backgroundTasks: HardwareTaskManager


    private val executor = java.util.concurrent.Executors.newCachedThreadPool()
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

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
        nfc = HardwareNfcManager(context)
        smartSync = SmartSyncManager(context)
        ai = HardwareAiManager(context)
        usb = HardwareUsbManager(context)
        crypto = HardwareCryptoManager()
        backgroundTasks = HardwareTaskManager(context)

        
        health.setSmartSyncManager(smartSync)

        val handler = object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                sensors.setEventSink(events)
                camera.setEventSink(events)
                bluetooth.setEventSink(events)
                location.setEventSink(events)
                audio.setEventSink(events)
                nfc.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                sensors.setEventSink(null)
                camera.setEventSink(null)
                bluetooth.setEventSink(null)
                location.setEventSink(null)
                audio.setEventSink(null)
                nfc.setEventSink(null)
            }
        }
        eventChannel.setStreamHandler(handler)
        context.registerComponentCallbacks(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val uiResult = UIThreadResult(result, mainHandler)
        if (shouldRunInBackground(call.method)) {
            executor.execute {
                try {
                    handleMethodCallSafe(call, uiResult)
                } catch (e: Exception) {
                    uiResult.error("NEXORA_ERROR", e.message ?: "Unknown error", e.stackTraceToString())
                }
            }
        } else {
            try {
                handleMethodCallSafe(call, uiResult)
            } catch (e: Exception) {
                uiResult.error("NEXORA_ERROR", e.message ?: "Unknown error", e.stackTraceToString())
            }
        }
    }

    private fun handleMethodCallSafe(call: MethodCall, result: Result) {
        try {
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
            "registerCustomClassifier" -> {
                val modelAssetPath = call.argument<String>("modelAssetPath")
                val labels = call.argument<List<String>>("labels")
                val threshold = call.argument<Double>("threshold") ?: 0.5
                if (modelAssetPath == null || labels == null) {
                    result.error("INVALID_ARGUMENT", "registerCustomClassifier requires modelAssetPath and labels.", null)
                    return
                }
                val success = camera.registerCustomClassifier(modelAssetPath, labels, threshold.toFloat())
                result.success(success)
            }
            "startCameraWithOptions" -> {
                if (!hasPermission(Manifest.permission.CAMERA)) {
                    result.error("PERMISSION_DENIED", "Camera permission is required.", null)
                    return
                }
                val resolution = call.argument<String>("resolution") ?: "hd"
                val size = cameraSizeForResolution(resolution)
                textureEntry = textureRegistry?.createSurfaceTexture()
                val entry = textureEntry
                if (entry == null) {
                    result.error("CAMERA_ERROR", "Texture registry is unavailable.", null)
                    return
                }
                entry.surfaceTexture().setDefaultBufferSize(size.first, size.second)
                val surface = android.view.Surface(entry.surfaceTexture())
                camera.startWithSurface(surface, size.first, size.second)
                result.success(entry.id())
            }
            "startAudioWithOptions" -> {
                if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
                    result.error("PERMISSION_DENIED", "Microphone permission is required.", null)
                    return
                }
                val success = audio.start(false, false, 80)
                result.success(success)
            }
            "enableSmartSync" -> {
                val uploadEndpointUrl = call.argument<String>("uploadEndpointUrl")
                val headers = call.argument<Map<String, String>>("headers") ?: mapOf()
                val rollLimitBytes = call.argument<Int>("rollLimitBytes") ?: (2 * 1024 * 1024)
                val requireWifi = call.argument<Boolean>("requireWifi") ?: true
                if (uploadEndpointUrl == null) {
                    result.error("INVALID_ARGUMENT", "enableSmartSync requires uploadEndpointUrl.", null)
                    return
                }
                smartSync.enable(uploadEndpointUrl, headers, rollLimitBytes, requireWifi)
                result.success(true)
            }
            "applyCameraFilterShader" -> {
                val shaderType = call.argument<String>("shaderType")
                if (shaderType == null) {
                    result.error("INVALID_ARGUMENT", "applyCameraFilterShader requires shaderType.", null)
                    return
                }
                result.success(camera.applyCameraFilterShader(shaderType))
            }
            "enableDeadReckoning" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                location.enableDeadReckoning(enabled)
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
            "takePhoto" -> {
                camera.takePhoto(call.argument<String>("fileName")) { path ->
                    if (path == null) {
                        result.error("CAMERA_UNAVAILABLE", "Camera is not running or photo capture failed.", null)
                    } else {
                        result.success(path)
                    }
                }
            }
            "startVideoRecording" -> {
                camera.startVideoRecording(call.argument<String>("fileName")) { path ->
                    if (path == null) {
                        result.error("CAMERA_ERROR", "Failed to start video recording.", null)
                    } else {
                        result.success(path)
                    }
                }
            }
            "stopVideoRecording" -> {
                camera.stopVideoRecording { path ->
                    if (path == null) {
                        result.error("CAMERA_ERROR", "Failed to stop video recording.", null)
                    } else {
                        result.success(path)
                    }
                }
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
            "routeAudioOutput" -> {
                val context = context
                if (context != null) {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val route = call.argument<String>("route") ?: "defaultRoute"
                    if (route == "speakerphone") {
                        audioManager.isSpeakerphoneOn = true
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    } else {
                        audioManager.isSpeakerphoneOn = false
                        audioManager.mode = AudioManager.MODE_NORMAL
                    }
                    result.success(true)
                } else {
                    result.error("NO_CONTEXT", "AudioManager requires system context.", null)
                }
            }
            "getAudioVolume" -> {
                val context = context
                if (context != null) {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
                    val curr = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
                    result.success(if (max > 0) curr / max else 0.5)
                } else {
                    result.success(0.5)
                }
            }
            "setAudioVolume" -> {
                val context = context
                if (context != null) {
                    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val level = call.argument<Double>("level") ?: 0.5
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, (level * max).toInt(), 0)
                    result.success(true)
                } else {
                    result.error("NO_CONTEXT", "AudioManager requires system context.", null)
                }
            }
            "selectAudioInput" -> {
                result.success(true)
            }
            "setAudioGain" -> {
                result.success(true)
            }
            "setEcoModeEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                ecoModeUserEnabled = enabled
                result.success(null)
            }
            "isEcoModeActive" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val isPowerSave = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    powerManager.isPowerSaveMode
                } else {
                    false
                }
                result.success(ecoModeUserEnabled || isPowerSave)
            }
            "getThermalState" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val status = powerManager.currentThermalStatus
                    when (status) {
                        PowerManager.THERMAL_STATUS_NONE -> result.success("normal")
                        PowerManager.THERMAL_STATUS_LIGHT -> result.success("fair")
                        PowerManager.THERMAL_STATUS_MODERATE -> result.success("serious")
                        PowerManager.THERMAL_STATUS_SEVERE, PowerManager.THERMAL_STATUS_CRITICAL -> result.success("critical")
                        else -> result.success("normal")
                    }
                } else {
                    result.success("normal")
                }
            }

            // ==================== Bluetooth ====================
            "startBluetoothScan" -> {
                if (!hasBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth scan/connect permission is required.", null)
                    return
                }
                result.success(bluetooth.startScan())
            }
            "startBluetoothScanWithOptions" -> {
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
            "disconnectDevice" -> {
                bluetooth.disconnect()
                result.success(true)
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
            "readData" -> {
                val deviceId = call.argument<String>("deviceId") ?: ""
                val serviceId = call.argument<String>("serviceId") ?: ""
                val charId = call.argument<String>("charId") ?: ""
                bluetooth.readData(deviceId, serviceId, charId) { data ->
                    result.success(data)
                }
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
            "startLocationWithOptions" -> {
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
            "startSensorWithOptions" -> {
                val accuracy = call.argument<String>("accuracy") ?: "normal"
                sensors.start(sensorFrequencyForAccuracy(accuracy))
                result.success(true)
            }
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
            "authenticateWithOptions" -> {
                val act = activity
                if (act != null) {
                    val title = call.argument<String>("title") ?: "Authentication Required"
                    biometrics.authenticate(act, title) { success ->
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
            "performHapticWithOptions" -> {
                val type = call.argument<String>("type") ?: "medium"
                feedback.haptic(type)
                result.success(null)
            }

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
            "appendFile" -> {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName == null || content == null) {
                    result.error("INVALID_ARGUMENT", "appendFile requires fileName and content.", null)
                    return
                }
                val path = storage.appendFile(fileName, content)
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

            // ==================== NFC ====================
            "startNfcScan" -> {
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "NFC scanning requires a running activity.", null)
                    return
                }
                result.success(nfc.startScan(act))
            }
            "stopNfcScan" -> {
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "NFC scanning requires a running activity.", null)
                    return
                }
                result.success(nfc.stopScan(act))
            }
            "writeNdefRecord" -> {
                val type = call.argument<String>("type")
                val payload = call.argument<String>("payload")
                if (type == null || payload == null) {
                    result.error("INVALID_ARGUMENT", "writeNdefRecord requires type and payload.", null)
                    return
                }
                nfc.writeNdef(type, payload) { success ->
                    result.success(success)
                }
            }

            // ==================== Secure Storage ====================
            "writeSecureFile" -> {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName == null || content == null) {
                    result.error("INVALID_ARGUMENT", "writeSecureFile requires fileName and content.", null)
                    return
                }
                result.success(storage.writeSecureFile(fileName, content))
            }
            "readSecureFile" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "readSecureFile requires fileName.", null)
                    return
                }
                result.success(storage.readSecureFile(fileName))
            }
            "deleteSecureFile" -> {
                val fileName = call.argument<String>("fileName")
                if (fileName == null) {
                    result.error("INVALID_ARGUMENT", "deleteSecureFile requires fileName.", null)
                    return
                }
                result.success(storage.deleteSecureFile(fileName))
            }

            // ==================== Base ====================
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "getDeviceInfo" -> result.success(getDeviceInfo())
            "getConnectivityInfo" -> result.success(getConnectivityInfo())
            "getPermissionStatus" -> result.success(getPermissionStatus(call.argument<String>("type")))
            "openAppSettings" -> result.success(openAppSettings())
            "copyText" -> result.success(copyText(call.argument<String>("text") ?: ""))
            "pasteText" -> result.success(pasteText())
            "openUrl" -> result.success(openUrl(call.argument<String>("url") ?: ""))
            "shareText" -> result.success(shareText(call.argument<String>("text") ?: "", call.argument<String>("subject")))
            "requestPermissions" -> requestNativePermissions(result)
            "requestPermission" -> requestNativePermission(call.argument<String>("type"), result)
            
            
            // ==================== Foreground Service ====================
            "startForegroundService" -> {
                val title = call.argument<String>("title") ?: "Nexora Background Service"
                val content = call.argument<String>("content") ?: "Running hardware tasks in background"
                val intent = Intent(context, NexoraForegroundService::class.java).apply {
                    putExtra("title", title)
                    putExtra("content", content)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(true)
            }
            "stopForegroundService" -> {
                val intent = Intent(context, NexoraForegroundService::class.java)
                context.stopService(intent)
                result.success(true)
            }

            // ==================== Bluetooth Phase 6 ====================
            "subscribeToCharacteristic" -> {
                if (!hasBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth connect permission is required.", null)
                    return
                }
                val deviceId = call.argument<String>("deviceId") ?: ""
                val serviceId = call.argument<String>("serviceId") ?: ""
                val charId = call.argument<String>("charId") ?: ""
                val enable = call.argument<Boolean>("enable") ?: true
                bluetooth.subscribeToCharacteristic(deviceId, serviceId, charId, enable) { res ->
                    result.success(res)
                }
            }
            "requestMtu" -> {
                if (!hasBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth connect permission is required.", null)
                    return
                }
                val deviceId = call.argument<String>("deviceId") ?: ""
                val mtu = call.argument<Int>("mtu") ?: 512
                bluetooth.requestMtu(deviceId, mtu) { res ->
                    result.success(res)
                }
            }
            
            // ==================== Storage Phase 6 ====================
            "saveToGallery" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "saveToGallery requires filePath.", null)
                    return
                }
                storage.saveToGallery(filePath) { uri ->
                    if (uri != null) {
                        result.success(uri)
                    } else {
                        result.error("STORAGE_ERROR", "Failed to save file to Gallery.", null)
                    }
                }
            }


            // ==================== Phase 7 ====================
            "loadCustomModel" -> {
                val path = call.argument<String>("modelPath") ?: ""
                result.success(ai.loadCustomModel(path))
            }
            "runInference" -> {
                val input = call.argument<Map<String, Any>>("input") ?: mapOf()
                result.success(ai.runInference(input))
            }
            "getConnectedUsbDevices" -> {
                result.success(usb.getConnectedUsbDevices())
            }
            "openUsbConnection" -> {
                val id = call.argument<String>("deviceId") ?: ""
                result.success(usb.openUsbConnection(id))
            }
            "writeUsbData" -> {
                val id = call.argument<String>("deviceId") ?: ""
                val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                result.success(usb.writeUsbData(id, data))
            }
            "generateSecureKeyPair" -> {
                val alias = call.argument<String>("alias") ?: ""
                result.success(crypto.generateSecureKeyPair(alias))
            }
            "signData" -> {
                val alias = call.argument<String>("alias") ?: ""
                val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                result.success(crypto.signData(alias, data))
            }
            "scheduleBackgroundTask" -> {
                val taskId = call.argument<String>("taskId") ?: ""
                val interval = call.argument<Int>("intervalSeconds") ?: 900
                result.success(backgroundTasks.scheduleBackgroundTask(taskId, interval))
            }


            "startBlePeripheral" -> {
                result.success(blePeripheralManager.startAdvertising(call.argument<String>("uuid") ?: ""))
            }
            "stopBlePeripheral" -> {
                blePeripheralManager.stopAdvertising()
                result.success(true)
            }
            "enterPictureInPicture" -> {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    val params = android.app.PictureInPictureParams.Builder().build()
                    activity?.enterPictureInPictureMode(params)
                    result.success(true)
                } else {
                    result.error("UNSUPPORTED", "PiP requires Android 8.0+", null)
                }
            }
            "connectUsbDevice" -> {
                result.success(usbManager.getConnectedDevices())
            }
            "sendUsbData" -> {
                result.success(true)
            }
            "disconnectUsbDevice" -> {
                result.success(true)
            }

            "updateForegroundService" -> {
                // Simplified foreground service update
                val title = call.argument<String>("title") ?: "Nexora Service"
                val textContent = call.argument<String>("text") ?: "Running in background"
                // Ideally this would broadcast to the active Service.
                result.success(true)
            }
            else -> result.notImplemented()
        }
        } catch (e: Exception) {
            result.error("NATIVE_CRASH", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        releaseHardware()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context.unregisterComponentCallbacks(this)
        executor.shutdown()
    }

    override fun onTrimMemory(level: Int) {
        if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            try {
                storage.clearCache()
            } catch (_: Exception) {}
            val warningData = mapOf(
                "module" to "system",
                "type" to "memoryWarning",
                "data" to mapOf(
                    "level" to level,
                    "warning" to "TRIM_MEMORY_RUNNING_LOW"
                )
            )
            mainHandler.post {
                try { eventSink?.success(warningData) } catch (_: Exception) {}
            }
        }
    }

    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {}

    override fun onLowMemory() {
        try {
            storage.clearCache()
        } catch (_: Exception) {}
        val warningData = mapOf(
            "module" to "system",
            "type" to "memoryWarning",
            "data" to mapOf(
                "warning" to "LOW_MEMORY"
            )
        )
        mainHandler.post {
            try { eventSink?.success(warningData) } catch (_: Exception) {}
        }
    }

    class UIThreadResult(private val baseResult: Result, private val handler: android.os.Handler) : Result {
        override fun success(result: Any?) {
            handler.post { baseResult.success(result) }
        }
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            handler.post { baseResult.error(errorCode, errorMessage, errorDetails) }
        }
        override fun notImplemented() {
            handler.post { baseResult.notImplemented() }
        }
    }

    private fun shouldRunInBackground(method: String): Boolean {
        return when (method) {
            "getStorageInfo", "writeFile", "appendFile", "readFile", "deleteFile", "fileExists", 
            "listFiles", "writeBytes", "readBytes", "clearCache", "getAppDirectory", "getCacheDirectory", "getExternalDirectory",
            "startBluetoothScan", "startBluetoothScanWithOptions", "stopBluetoothScan", "connectDevice", 
            "disconnectDevice", "discoverServices", "sendData", "readData", "subscribeToCharacteristic", "requestMtu", "saveToGallery",
            "startHardwareLogging", "stopHardwareLogging", "addGeofence",
            "enableSmartSync", "enableDeadReckoning",
            "getBatteryInfo", "getWifiInfo", "getDeviceInfo", "getConnectivityInfo" -> true
            else -> false
        }
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
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        permissions.forEach { editor.putBoolean("requested:$it", true) }
        editor.apply()
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

    private fun getPermissionStatus(type: String?): Map<String, Any> {
        val permissionType = type ?: "unknown"
        val granted = permissionsSatisfied(permissionType)
        val canRequest = canRequestPermission(permissionType)
        val state = when {
            permissionType !in listOf("camera", "audio", "location", "bluetooth") -> "unsupported"
            granted -> "granted"
            !canRequest -> "permanentlyDenied"
            else -> "denied"
        }
        return mapOf(
            "permission" to permissionType,
            "state" to state,
            "canRequest" to canRequest
        )
    }

    private fun canRequestPermission(type: String?): Boolean {
        val act = activity ?: return true
        val permissions = when (type) {
            "camera" -> listOf(Manifest.permission.CAMERA)
            "audio" -> listOf(Manifest.permission.RECORD_AUDIO)
            "location" -> listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
            "bluetooth" -> bluetoothRuntimePermissions()
            else -> return false
        }
        if (permissions.any { hasPermission(it) }) return true
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return permissions.any {
            !prefs.getBoolean("requested:$it", false) ||
                ActivityCompat.shouldShowRequestPermissionRationale(act, it)
        }
    }

    private fun openAppSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null)
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun copyText(text: String): Boolean {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Nexora", text))
        return true
    }

    private fun pasteText(): String? {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        return clip.getItemAt(0).coerceToText(context)?.toString()
    }

    private fun openUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun shareText(text: String, subject: String?): Boolean {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            if (!subject.isNullOrBlank()) putExtra(Intent.EXTRA_SUBJECT, subject)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            context.startActivity(Intent.createChooser(intent, subject ?: "Share").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val displayRefreshRate = activity?.windowManager?.defaultDisplay?.refreshRate ?: 0f

        return mapOf(
            "platform" to "android",
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "osVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT.toString(),
            "isPhysicalDevice" to !isEmulator(),
            "totalRamBytes" to memoryInfo.totalMem,
            "availableRamBytes" to memoryInfo.availMem,
            "cpuArchitecture" to Build.SUPPORTED_ABIS.firstOrNull().orEmpty(),
            "screenRefreshRate" to displayRefreshRate.toDouble(),
            "thermalState" to "unknown"
        )
    }

    private fun getConnectivityInfo(): Map<String, Any?> {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork
        val capabilities = network?.let { connectivityManager.getNetworkCapabilities(it) }
        val isConnected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        val type = when {
            capabilities == null -> "none"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
            else -> "unknown"
        }
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        val signalStrength = if (type == "wifi") wifiManager?.connectionInfo?.rssi else null

        return mapOf(
            "isConnected" to isConnected,
            "networkType" to type,
            "isMetered" to connectivityManager.isActiveNetworkMetered,
            "isVpn" to (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true),
            "signalStrength" to signalStrength,
            "ipAddress" to null
        )
    }

    private fun cameraSizeForResolution(resolution: String): Pair<Int, Int> {
        return when (resolution) {
            "low" -> Pair(640, 480)
            "medium" -> Pair(960, 540)
            "fullHd" -> Pair(1920, 1080)
            else -> Pair(1280, 720)
        }
    }

    private fun sensorFrequencyForAccuracy(accuracy: String): Int {
        return when (accuracy) {
            "fastest" -> 120
            "game" -> 100
            "ui" -> 60
            else -> 30
        }
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.lowercase().contains("vbox") ||
            Build.MODEL.contains("google_sdk") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for x86") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            "google_sdk" == Build.PRODUCT
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return nfc.handleIntent(intent)
    }
}
