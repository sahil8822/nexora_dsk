package com.example.nexora_sdk

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/**
 * Optimized Nexora SDK Plugin.
 * Handles unified hardware management with improved API safety.
 */
class NexoraSdk: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
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

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        textureRegistry = flutterPluginBinding.textureRegistry
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/methods")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexora_sdk/events")
        
        // Initialize Modules
        camera = HardwareCameraManager(context)
        audio = HardwareAudioModule(context)
        sensors = HardwareSensorManager(context)
        bluetooth = HardwareBluetoothManager(context)
        location = HardwareLocationManager(context)
        biometrics = HardwareBiometricManager(context)
        feedback = HardwareFeedbackManager(context)
        health = HardwareHealthManager(context)

        val handler = HardwareStreamHandler(context, sensors, camera, bluetooth, location, audio)
        eventChannel.setStreamHandler(handler)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startCamera" -> {
                val width = call.argument<Int>("width") ?: 640
                val height = call.argument<Int>("height") ?: 480
                
                textureEntry = textureRegistry?.createSurfaceTexture()
                val surface = android.view.Surface(textureEntry?.surfaceTexture())
                camera.setEventSink(null) // Reset if needed
                camera.startWithSurface(surface, width, height)
                
                result.success(textureEntry?.id())
            }
            "stopCamera" -> {
                camera.stop()
                textureEntry?.release()
                textureEntry = null
                result.success(true)
            }
            "setVisionMode" -> {
                camera.setVisionMode(call.argument<Boolean>("face") ?: false, call.argument<Boolean>("barcode") ?: false)
                result.success(true)
            }
            "startAudio" -> result.success(audio.start(call.argument<Boolean>("enableFFT") ?: false))
            "stopAudio" -> { audio.stop(); result.success(true) }
            
            // --- Security & Health ---
            "authenticate" -> {
                val act = activity
                if (act != null) {
                    biometrics.authenticate(act, call.argument<String>("reason") ?: "Authentication Required", { success ->
                        result.success(success)
                    })
                } else {
                    result.error("NO_ACTIVITY", "Biometric authentication requires a foreground activity", null)
                }
            }
            "canAuthenticate" -> result.success(biometrics.canAuthenticate())
            "vibrate" -> { feedback.vibrate((call.argument<Int>("duration") ?: 50).toLong()); result.success(null) }
            "hapticFeedback" -> { feedback.haptic(call.argument<String>("type") ?: "impact"); result.success(null) }
            "getBatteryInfo" -> result.success(health.getBatteryInfo())
            "startLogging" -> {
                health.startLogging(call.argument<String>("fileName") ?: "log.csv", (call.argument<Int>("interval") ?: 1000).toLong())
                result.success(true)
            }
            "stopLogging" -> { health.stopLogging(); result.success(true) }

            // --- Bluetooth & GPS ---
            "startBluetoothScan" -> { bluetooth.startScan(); result.success(true) }
            "stopBluetoothScan" -> { bluetooth.stopScan(); result.success(true) }
            "startLocation" -> { location.startUpdates(); result.success(true) }
            "stopLocation" -> { location.stopUpdates(); result.success(true) }
            "addGeofence" -> {
                location.addGeofence(call.argument<String>("id")!!, call.argument<Double>("lat")!!, call.argument<Double>("lon")!!, (call.argument<Double>("radius")!!).toFloat())
                result.success(true)
            }

            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "requestPermissions" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
}
