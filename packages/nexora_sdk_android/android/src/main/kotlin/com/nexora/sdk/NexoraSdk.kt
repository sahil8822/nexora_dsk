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
import android.media.AudioManager
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

import com.nexora.sdk.pigeon.*

/**
 * Nexora SDK — Complete Native Plugin with type-safe Pigeon host APIs.
 */
class NexoraSdk: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.NewIntentListener, android.content.ComponentCallbacks2,
    HardwareApi,
    AudioApi,
    LocationApi,
    SensorApi,
    BiometricsApi,
    BluetoothApi,
    SecureStorageApi,
    SystemApi {
    
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
    private var sdkConfig: Map<String, Any?> = emptyMap()
    private var logNativeCalls = false
    private var androidOptions: Map<String, Any?> = emptyMap()

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
    private lateinit var blePeripheralManager: HardwareBlePeripheralManager
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
        blePeripheralManager = HardwareBlePeripheralManager(context)
        crypto = HardwareCryptoManager()
        backgroundTasks = HardwareTaskManager(context)

        health.setSmartSyncManager(smartSync)

        val handler = object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                sensors.setEventSink(events)
                camera.setEventSink(events)
                bluetooth.setEventSink(events)
                blePeripheralManager.setEventSink(events)
                location.setEventSink(events)
                audio.setEventSink(events)
                nfc.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                sensors.setEventSink(null)
                camera.setEventSink(null)
                bluetooth.setEventSink(null)
                blePeripheralManager.setEventSink(null)
                location.setEventSink(null)
                audio.setEventSink(null)
                nfc.setEventSink(null)
            }
        }
        eventChannel.setStreamHandler(handler)
        context.registerComponentCallbacks(this)

        // Set up Pigeon host APIs
        HardwareApi.setUp(flutterPluginBinding.binaryMessenger, this)
        AudioApi.setUp(flutterPluginBinding.binaryMessenger, this)
        LocationApi.setUp(flutterPluginBinding.binaryMessenger, this)
        SensorApi.setUp(flutterPluginBinding.binaryMessenger, this)
        BiometricsApi.setUp(flutterPluginBinding.binaryMessenger, this)
        BluetoothApi.setUp(flutterPluginBinding.binaryMessenger, this)
        SecureStorageApi.setUp(flutterPluginBinding.binaryMessenger, this)
        SystemApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        // Fallback for legacy MethodChannel calls, delegating to the safe handler
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
        // Legacy routing mapping (kept for binary backward compatibility)
        try {
            when (call.method) {
                "configureSdk" -> {
                    sdkConfig = call.arguments as? Map<String, Any?> ?: emptyMap()
                    logNativeCalls = sdkConfig["logNativeCalls"] as? Boolean ?: false
                    androidOptions = sdkConfig["android"] as? Map<String, Any?> ?: emptyMap()
                    applyAndroidOptions(androidOptions)
                    result.success(true)
                }
                "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                "connectL2cap" -> {
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val deviceId = args["deviceId"] as? String ?: ""
                    val psm = (args["psm"] as? Number)?.toInt() ?: 0
                    val success = bluetooth.connectL2cap(deviceId, psm)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NATIVE_CRASH", e.message, null)
        }
    }

    // --- HardwareApi ---

    override fun startCamera(width: Long, height: Long, callback: (kotlin.Result<Long>) -> Unit) {
        mainHandler.post {
            try {
                if (!hasPermission(Manifest.permission.CAMERA)) {
                    callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Camera permission is required.")))
                    return@post
                }
                textureEntry = textureRegistry?.createSurfaceTexture()
                val entry = textureEntry
                if (entry == null) {
                    callback(kotlin.Result.failure(FlutterError("CAMERA_ERROR", "Texture registry is unavailable.")))
                    return@post
                }
                entry.surfaceTexture().setDefaultBufferSize(width.toInt(), height.toInt())
                val surface = android.view.Surface(entry.surfaceTexture())
                camera.startWithSurface(surface, width.toInt(), height.toInt())
                callback(kotlin.Result.success(entry.id()))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun startCameraWithOptions(options: NexoraCameraOptions, callback: (kotlin.Result<Long>) -> Unit) {
        mainHandler.post {
            try {
                if (!hasPermission(Manifest.permission.CAMERA)) {
                    callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Camera permission is required.")))
                    return@post
                }
                val resolution = options.resolution ?: "hd"
                val size = cameraSizeForResolution(resolution)
                textureEntry = textureRegistry?.createSurfaceTexture()
                val entry = textureEntry
                if (entry == null) {
                    callback(kotlin.Result.failure(FlutterError("CAMERA_ERROR", "Texture registry is unavailable.")))
                    return@post
                }
                entry.surfaceTexture().setDefaultBufferSize(size.first, size.second)
                val surface = android.view.Surface(entry.surfaceTexture())
                camera.startWithSurface(surface, size.first, size.second)
                callback(kotlin.Result.success(entry.id()))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun stopCamera(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                camera.stop()
                textureEntry?.release()
                textureEntry = null
                callback(kotlin.Result.success(true))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun setVisionMode(options: VisionModeOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                camera.setVisionMode(
                    options.face ?: false,
                    options.barcode ?: false
                )
                callback(kotlin.Result.success(true))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun registerCustomClassifier(options: CustomClassifierOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                val modelAssetPath = options.modelAssetPath
                val labels = options.labels
                val threshold = options.threshold ?: 0.5
                if (modelAssetPath == null || labels == null) {
                    callback(kotlin.Result.failure(FlutterError("INVALID_ARGUMENT", "registerCustomClassifier requires modelAssetPath and labels.")))
                    return@post
                }
                val success = camera.registerCustomClassifier(modelAssetPath, labels.filterNotNull(), threshold.toFloat())
                callback(kotlin.Result.success(success))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun setFlash(on: Boolean, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                camera.setFlash(on)
                callback(kotlin.Result.success(true))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun setZoom(level: Double, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                camera.setZoom(level.toFloat())
                callback(kotlin.Result.success(true))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun flipCamera(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                camera.flipCamera()
                callback(kotlin.Result.success(true))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun takePhoto(fileName: String?, callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post {
            try {
                camera.takePhoto(fileName) { path ->
                    callback(kotlin.Result.success(path))
                }
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun startVideoRecording(fileName: String?, callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post {
            try {
                camera.startVideoRecording(fileName) { path ->
                    callback(kotlin.Result.success(path))
                }
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun stopVideoRecording(callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post {
            try {
                camera.stopVideoRecording { path ->
                    callback(kotlin.Result.success(path))
                }
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    override fun applyCameraFilterShader(shaderType: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            try {
                callback(kotlin.Result.success(camera.applyCameraFilterShader(shaderType)))
            } catch (e: Exception) {
                callback(kotlin.Result.failure(e))
            }
        }
    }

    // --- AudioApi ---

    override fun startAudio(options: BasicAudioOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Microphone permission is required."))) }
                    return@execute
                }
                val success = audio.start(
                    options.enableFFT ?: false,
                    options.streamBytes ?: false,
                    (options.updateIntervalMs ?: 80).toInt()
                )
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun startAudioWithOptions(options: NexoraAudioOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Microphone permission is required."))) }
                    return@execute
                }
                val success = audio.start(false, false, 80)
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun stopAudio(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                audio.stop()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun routeAudioOutput(route: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                if (route == "speakerphone") {
                    audioManager.isSpeakerphoneOn = true
                    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                } else {
                    audioManager.isSpeakerphoneOn = false
                    audioManager.mode = AudioManager.MODE_NORMAL
                }
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun getAudioVolume(callback: (kotlin.Result<Double>) -> Unit) {
        executor.execute {
            try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
                val curr = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
                val volume = if (max > 0) curr / max else 0.5
                mainHandler.post { callback(kotlin.Result.success(volume)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun setAudioVolume(level: Double, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, (level * max).toInt(), 0)
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun selectAudioInput(device: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post { callback(kotlin.Result.success(true)) }
    }

    override fun setAudioGain(gain: Double, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post { callback(kotlin.Result.success(true)) }
    }

    // --- LocationApi ---

    override fun startLocation(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasLocationPermission()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Location permission is required."))) }
                    return@execute
                }
                location.startUpdates()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun startLocationWithOptions(options: NexoraLocationOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasLocationPermission()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Location permission is required."))) }
                    return@execute
                }
                location.startUpdates()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun stopLocation(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                location.stopUpdates()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun setBackgroundLocationEnabled(enabled: Boolean, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                location.setBackgroundEnabled(enabled)
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    // --- SensorApi ---

    override fun startSensor(frequencyHz: Long, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                sensors.start(frequencyHz.toInt())
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun startSensorWithOptions(options: NexoraSensorOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val freq = options.frequencyHz?.toInt() ?: 60
                sensors.start(freq)
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun stopSensor(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                sensors.stop()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun enableDeadReckoning(enabled: Boolean, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                location.enableDeadReckoning(enabled)
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    // --- BiometricsApi ---

    override fun authenticate(reason: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val act = activity
            if (act != null) {
                biometrics.authenticate(act, reason) { success ->
                    callback(kotlin.Result.success(success))
                }
            } else {
                callback(kotlin.Result.failure(FlutterError("NO_ACTIVITY", "Biometric authentication requires a foreground activity.")))
            }
        }
    }

    override fun authenticateWithOptions(options: NexoraBiometricOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val act = activity
            if (act != null) {
                val title = options.title ?: "Authentication Required"
                biometrics.authenticate(act, title) { success ->
                    callback(kotlin.Result.success(success))
                }
            } else {
                callback(kotlin.Result.failure(FlutterError("NO_ACTIVITY", "Biometric authentication requires a foreground activity.")))
            }
        }
    }

    override fun canAuthenticate(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(biometrics.canAuthenticate()))
        }
    }

    // --- BluetoothApi ---

    override fun startBluetoothScan(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasBluetoothPermissions()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Bluetooth scan/connect permission is required."))) }
                    return@execute
                }
                val success = bluetooth.startScan()
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun startBluetoothScanWithOptions(options: NexoraBluetoothScanOptions, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasBluetoothPermissions()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Bluetooth scan/connect permission is required."))) }
                    return@execute
                }
                val success = bluetooth.startScan()
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun stopBluetoothScan(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val success = bluetooth.stopScan()
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun connectDevice(id: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasBluetoothPermissions()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Bluetooth connect permission is required."))) }
                    return@execute
                }
                val success = bluetooth.connect(id)
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun disconnectDevice(id: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                bluetooth.disconnect()
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun discoverServices(deviceId: String, callback: (kotlin.Result<List<String?>>) -> Unit) {
        executor.execute {
            try {
                bluetooth.discoverServices(deviceId) { services ->
                    mainHandler.post { callback(kotlin.Result.success(services)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun sendData(deviceId: String, serviceId: String, charId: String, data: List<Long?>, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val byteArray = data.filterNotNull().map { it.toByte() }.toByteArray()
                val success = bluetooth.sendData(deviceId, serviceId, charId, byteArray)
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun readData(deviceId: String, serviceId: String, charId: String, callback: (kotlin.Result<ByteArray?>) -> Unit) {
        executor.execute {
            try {
                bluetooth.readData(deviceId, serviceId, charId) { response ->
                    mainHandler.post { callback(kotlin.Result.success(response)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun subscribeToCharacteristic(deviceId: String, serviceId: String, charId: String, enable: Boolean, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasBluetoothPermissions()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Bluetooth connect permission is required."))) }
                    return@execute
                }
                bluetooth.subscribeToCharacteristic(deviceId, serviceId, charId, enable) { res ->
                    mainHandler.post { callback(kotlin.Result.success(res)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun requestMtu(deviceId: String, mtu: Long, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                if (!hasBluetoothPermissions()) {
                    mainHandler.post { callback(kotlin.Result.failure(FlutterError("PERMISSION_DENIED", "Bluetooth connect permission is required."))) }
                    return@execute
                }
                bluetooth.requestMtu(deviceId, mtu.toInt()) { res ->
                    mainHandler.post { callback(kotlin.Result.success(res)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun startBlePeripheral(uuid: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val success = blePeripheralManager.startAdvertising(uuid)
                mainHandler.post { callback(kotlin.Result.success(success)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun stopBlePeripheral(callback: (kotlin.Result<Unit>) -> Unit) {
        executor.execute {
            try {
                blePeripheralManager.stopAdvertising()
                mainHandler.post { callback(kotlin.Result.success(Unit)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    // --- SecureStorageApi ---

    override fun getStorageInfo(callback: (kotlin.Result<NexoraStorageInfo?>) -> Unit) {
        executor.execute {
            try {
                val info = storage.getStorageInfo()
                val storageInfo = NexoraStorageInfo(
                    internalTotal = info["internalTotal"] as? Long,
                    internalFree = info["internalFree"] as? Long,
                    externalTotal = info["externalTotal"] as? Long,
                    externalFree = info["externalFree"] as? Long,
                    appCacheSize = info["appCacheSize"] as? Long,
                    appDataSize = info["appDataSize"] as? Long
                )
                mainHandler.post { callback(kotlin.Result.success(storageInfo)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun writeFile(fileName: String, content: String, callback: (kotlin.Result<String?>) -> Unit) {
        executor.execute {
            try {
                val path = storage.writeFile(fileName, content)
                mainHandler.post { callback(kotlin.Result.success(path)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun appendFile(fileName: String, content: String, callback: (kotlin.Result<String?>) -> Unit) {
        executor.execute {
            try {
                val path = storage.appendFile(fileName, content)
                mainHandler.post { callback(kotlin.Result.success(path)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun readFile(fileName: String, callback: (kotlin.Result<String?>) -> Unit) {
        executor.execute {
            try {
                val content = storage.readFile(fileName)
                mainHandler.post { callback(kotlin.Result.success(content)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun deleteFile(fileName: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val deleted = storage.deleteFile(fileName)
                mainHandler.post { callback(kotlin.Result.success(deleted)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun fileExists(fileName: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val exists = storage.fileExists(fileName)
                mainHandler.post { callback(kotlin.Result.success(exists)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun listFiles(callback: (kotlin.Result<List<NexoraFileInfo?>>) -> Unit) {
        executor.execute {
            try {
                val list = storage.listFiles() ?: emptyList<Map<String, Any>>()
                val fileInfos = list.map { item ->
                    NexoraFileInfo(
                        name = item["name"] as? String,
                        size = (item["size"] as? Number)?.toLong(),
                        isDirectory = item["isDirectory"] as? Boolean,
                        lastModifiedMs = (item["lastModified"] as? Number)?.toLong()
                    )
                }
                mainHandler.post { callback(kotlin.Result.success(fileInfos)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun writeBytes(fileName: String, bytes: ByteArray, callback: (kotlin.Result<String?>) -> Unit) {
        executor.execute {
            try {
                val path = storage.writeBytes(fileName, bytes)
                mainHandler.post { callback(kotlin.Result.success(path)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun readBytes(fileName: String, callback: (kotlin.Result<ByteArray?>) -> Unit) {
        executor.execute {
            try {
                val data = storage.readBytes(fileName)
                mainHandler.post { callback(kotlin.Result.success(data)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun clearCache(callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val cleared = storage.clearCache()
                mainHandler.post { callback(kotlin.Result.success(cleared)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun getAppDirectory(callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post { callback(kotlin.Result.success(storage.getAppDirectory())) }
    }

    override fun getCacheDirectory(callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post { callback(kotlin.Result.success(storage.getCacheDirectory())) }
    }

    override fun getExternalDirectory(callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post { callback(kotlin.Result.success(storage.getExternalDirectory())) }
    }

    // --- SystemApi ---

    override fun configureSdk(config: NexoraSdkConfig, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val confMap = mutableMapOf<String, Any?>()
            confMap["enableLogging"] = config.enableLogging
            confMap["ecoMode"] = config.ecoMode
            sdkConfig = confMap
            logNativeCalls = config.enableLogging ?: false
            callback(kotlin.Result.success(true))
        }
    }

    override fun requestPermissions(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val act = activity
            if (act == null) {
                callback(kotlin.Result.success(hasAllCriticalPermissions()))
                return@post
            }
            val missing = criticalRuntimePermissions().filter { !hasPermission(it) }.toTypedArray()
            if (missing.isEmpty()) {
                callback(kotlin.Result.success(true))
                return@post
            }
            if (pendingPermissionResult != null) {
                callback(kotlin.Result.failure(FlutterError("PERMISSION_REQUEST_IN_PROGRESS", "A permission request is already running.")))
                return@post
            }
            val wrapperResult = object : Result {
                override fun success(res: Any?) {
                    callback(kotlin.Result.success(res as? Boolean ?: false))
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    callback(kotlin.Result.failure(FlutterError(code, msg, details)))
                }
                override fun notImplemented() {
                    callback(kotlin.Result.failure(FlutterError("NOT_IMPLEMENTED", "Not implemented")))
                }
            }
            pendingPermissionResult = wrapperResult
            pendingPermissionType = null
            act.requestPermissions(missing, PERMISSION_REQUEST_CODE)
        }
    }

    override fun requestPermission(type: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val permissions = when (type) {
                "camera" -> listOf(Manifest.permission.CAMERA)
                "audio" -> listOf(Manifest.permission.RECORD_AUDIO)
                "location" -> listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
                "bluetooth" -> bluetoothRuntimePermissions()
                else -> {
                    callback(kotlin.Result.failure(FlutterError("INVALID_ARGUMENT", "Unknown permission type: $type")))
                    return@post
                }
            }
            val act = activity
            if (act == null) {
                callback(kotlin.Result.success(permissionsSatisfied(type)))
                return@post
            }
            val missing = permissions.filter { !hasPermission(it) }.toTypedArray()
            if (missing.isEmpty()) {
                callback(kotlin.Result.success(true))
                return@post
            }
            if (pendingPermissionResult != null) {
                callback(kotlin.Result.failure(FlutterError("PERMISSION_REQUEST_IN_PROGRESS", "A permission request is already running.")))
                return@post
            }
            val wrapperResult = object : Result {
                override fun success(res: Any?) {
                    callback(kotlin.Result.success(res as? Boolean ?: false))
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    callback(kotlin.Result.failure(FlutterError(code, msg, details)))
                }
                override fun notImplemented() {
                    callback(kotlin.Result.failure(FlutterError("NOT_IMPLEMENTED", "Not implemented")))
                }
            }
            pendingPermissionResult = wrapperResult
            pendingPermissionType = type
            act.requestPermissions(missing, PERMISSION_REQUEST_CODE)
        }
    }

    override fun getPermissionStatus(type: String, callback: (kotlin.Result<NexoraPermissionStatus>) -> Unit) {
        mainHandler.post {
            val statusMap = getPermissionStatus(type)
            val state = statusMap["state"] as? String ?: "denied"
            val canRequest = statusMap["canRequest"] as? Boolean ?: false
            callback(kotlin.Result.success(NexoraPermissionStatus(type, state, canRequest)))
        }
    }

    override fun openAppSettings(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(openAppSettings()))
        }
    }

    override fun getDeviceInfo(callback: (kotlin.Result<NexoraDeviceInfo>) -> Unit) {
        executor.execute {
            try {
                val info = getDeviceInfo()
                val deviceInfo = NexoraDeviceInfo(
                    platform = info["platform"] as? String,
                    manufacturer = info["manufacturer"] as? String,
                    model = info["model"] as? String,
                    osVersion = info["osVersion"] as? String,
                    sdkVersion = info["sdkVersion"] as? String,
                    isPhysicalDevice = info["isPhysicalDevice"] as? Boolean,
                    totalRamBytes = info["totalRamBytes"] as? Long,
                    availableRamBytes = info["availableRamBytes"] as? Long,
                    cpuArchitecture = info["cpuArchitecture"] as? String,
                    screenRefreshRate = info["screenRefreshRate"] as? Double,
                    thermalState = info["thermalState"] as? String
                )
                mainHandler.post { callback(kotlin.Result.success(deviceInfo)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun getConnectivityInfo(callback: (kotlin.Result<NexoraConnectivityInfo>) -> Unit) {
        executor.execute {
            try {
                val info = getConnectivityInfo()
                val connInfo = NexoraConnectivityInfo(
                    isConnected = info["isConnected"] as? Boolean,
                    networkType = info["networkType"] as? String,
                    isMetered = info["isMetered"] as? Boolean,
                    isVpn = info["isVpn"] as? Boolean,
                    signalStrength = (info["signalStrength"] as? Number)?.toLong(),
                    ipAddress = info["ipAddress"] as? String
                )
                mainHandler.post { callback(kotlin.Result.success(connInfo)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun getBatteryInfo(callback: (kotlin.Result<NexoraBatteryInfo?>) -> Unit) {
        executor.execute {
            try {
                val info = health.getBatteryInfo()
                if (info != null) {
                    val batteryInfo = NexoraBatteryInfo(
                        level = info["level"] as? Double,
                        isCharging = info["isCharging"] as? Boolean,
                        status = info["status"] as? String,
                        temperature = info["temperature"] as? Double
                    )
                    mainHandler.post { callback(kotlin.Result.success(batteryInfo)) }
                } else {
                    mainHandler.post { callback(kotlin.Result.success(null)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun getWifiInfo(callback: (kotlin.Result<NexoraWifiInfo?>) -> Unit) {
        executor.execute {
            try {
                val info = health.getWifiInfo()
                if (info != null) {
                    val wifiInfo = NexoraWifiInfo(
                        ssid = info["ssid"] as? String,
                        bssid = info["bssid"] as? String,
                        signalStrength = (info["signalStrength"] as? Number)?.toLong(),
                        frequency = (info["frequency"] as? Number)?.toLong(),
                        linkSpeed = (info["linkSpeed"] as? Number)?.toLong()
                    )
                    mainHandler.post { callback(kotlin.Result.success(wifiInfo)) }
                } else {
                    mainHandler.post { callback(kotlin.Result.success(null)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun vibrate(durationMs: Long, callback: (kotlin.Result<Unit>) -> Unit) {
        mainHandler.post {
            feedback.vibrate(durationMs)
            callback(kotlin.Result.success(Unit))
        }
    }

    override fun hapticFeedback(type: String, callback: (kotlin.Result<Unit>) -> Unit) {
        mainHandler.post {
            feedback.haptic(type)
            callback(kotlin.Result.success(Unit))
        }
    }

    override fun performHapticWithOptions(options: NexoraHapticOptions, callback: (kotlin.Result<Unit>) -> Unit) {
        mainHandler.post {
            feedback.haptic(options.type ?: "medium")
            callback(kotlin.Result.success(Unit))
        }
    }

    override fun copyText(text: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(copyText(text)))
        }
    }

    override fun pasteText(callback: (kotlin.Result<String?>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(pasteText()))
        }
    }

    override fun openUrl(url: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(openUrl(url)))
        }
    }

    override fun shareText(text: String, subject: String?, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(shareText(text, subject)))
        }
    }

    override fun saveToGallery(filePath: String, callback: (kotlin.Result<String?>) -> Unit) {
        executor.execute {
            try {
                storage.saveToGallery(filePath) { uri ->
                    mainHandler.post { callback(kotlin.Result.success(uri)) }
                }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun enterPictureInPicture(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val params = android.app.PictureInPictureParams.Builder().build()
                val pipResult = activity?.enterPictureInPictureMode(params) ?: false
                callback(kotlin.Result.success(pipResult))
            } else {
                callback(kotlin.Result.failure(FlutterError("UNSUPPORTED", "PiP requires Android 8.0+")))
            }
        }
    }

    override fun getConnectedUsbDevices(callback: (kotlin.Result<List<String?>>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(usb.getConnectedDevices()))
        }
    }

    override fun startForegroundService(title: String, content: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val intent = Intent(context, NexoraForegroundService::class.java).apply {
                putExtra("title", title)
                putExtra("content", content)
                putExtra("channelId", "NexoraHardwareChannel")
                putExtra("channelName", title)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            callback(kotlin.Result.success(true))
        }
    }

    override fun updateForegroundService(title: String, text: String, callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            callback(kotlin.Result.success(true))
        }
    }

    override fun stopForegroundService(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val intent = Intent(context, NexoraForegroundService::class.java)
            context.stopService(intent)
            callback(kotlin.Result.success(true))
        }
    }

    override fun enableSmartSync(uploadEndpointUrl: String, headers: Map<String?, String?>, rollLimitBytes: Long, requireWifi: Boolean, callback: (kotlin.Result<Boolean>) -> Unit) {
        executor.execute {
            try {
                val nonNullHeaders = headers.filterKeys { it != null }.filterValues { it != null } as Map<String, String>
                smartSync.enable(uploadEndpointUrl, nonNullHeaders, rollLimitBytes.toInt(), requireWifi)
                mainHandler.post { callback(kotlin.Result.success(true)) }
            } catch (e: Exception) {
                mainHandler.post { callback(kotlin.Result.failure(e)) }
            }
        }
    }

    override fun setEcoModeEnabled(enabled: Boolean, callback: (kotlin.Result<Unit>) -> Unit) {
        mainHandler.post {
            ecoModeUserEnabled = enabled
            callback(kotlin.Result.success(Unit))
        }
    }

    override fun isEcoModeActive(callback: (kotlin.Result<Boolean>) -> Unit) {
        mainHandler.post {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val isPowerSave = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                powerManager.isPowerSaveMode
            } else {
                false
            }
            callback(kotlin.Result.success(ecoModeUserEnabled || isPowerSave))
        }
    }

    override fun getThermalState(callback: (kotlin.Result<String>) -> Unit) {
        mainHandler.post {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val state = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                when (powerManager.currentThermalStatus) {
                    PowerManager.THERMAL_STATUS_NONE -> "normal"
                    PowerManager.THERMAL_STATUS_LIGHT -> "fair"
                    PowerManager.THERMAL_STATUS_MODERATE -> "serious"
                    PowerManager.THERMAL_STATUS_SEVERE, PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
                    else -> "normal"
                }
            } else {
                "normal"
            }
            callback(kotlin.Result.success(state))
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        releaseHardware()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context.unregisterComponentCallbacks(this)
        executor.shutdown()

        // Clean up Pigeon host APIs
        HardwareApi.setUp(binding.binaryMessenger, null)
        AudioApi.setUp(binding.binaryMessenger, null)
        LocationApi.setUp(binding.binaryMessenger, null)
        SensorApi.setUp(binding.binaryMessenger, null)
        BiometricsApi.setUp(binding.binaryMessenger, null)
        BluetoothApi.setUp(binding.binaryMessenger, null)
        SecureStorageApi.setUp(binding.binaryMessenger, null)
        SystemApi.setUp(binding.binaryMessenger, null)
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
            "configureSdk" -> true
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

    @Suppress("UNCHECKED_CAST")
    private fun applyAndroidOptions(options: Map<String, Any?>) {
        val cameraOptions = options["camera"] as? Map<String, Any?> ?: emptyMap()
        camera.configure(cameraOptions)

        val audioOptions = options["audio"] as? Map<String, Any?> ?: emptyMap()
        val rootAudioOptions = sdkConfig["audio"] as? Map<String, Any?> ?: emptyMap()
        audio.configure(rootAudioOptions + audioOptions)

        val locationOptions = options["location"] as? Map<String, Any?> ?: emptyMap()
        location.configure(locationOptions)

        val bluetoothOptions = options["bluetooth"] as? Map<String, Any?> ?: emptyMap()
        bluetooth.configure(bluetoothOptions)

        val sensorOptions = options["sensors"] as? Map<String, Any?> ?: emptyMap()
        sensors.configure(sensorOptions)

        val biometricOptions = options["biometrics"] as? Map<String, Any?> ?: emptyMap()
        biometrics.configure(biometricOptions)

        val systemOptions = options["system"] as? Map<String, Any?> ?: emptyMap()
        val keepScreenOn = systemOptions["keepScreenOn"] as? Boolean ?: false
        activity?.window?.let { window ->
            if (keepScreenOn) {
                window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }

        val rootLocationOptions = sdkConfig["location"] as? Map<String, Any?> ?: emptyMap()
        val locationBackground = rootLocationOptions["enableBackgroundUpdates"] as? Boolean
        if (locationBackground != null) {
            location.setBackgroundEnabled(locationBackground)
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
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return nfc.handleIntent(intent)
    }
}
