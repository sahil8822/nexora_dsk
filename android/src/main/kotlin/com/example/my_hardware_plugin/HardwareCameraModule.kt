package com.example.my_hardware_plugin

import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryCodec
import java.nio.ByteBuffer

/**
 * High-performance Camera module for Android.
 * Streams raw binary frame data via BasicMessageChannel to minimize bridge latency.
 */
class HardwareCameraModule(private val context: Context, messenger: BinaryMessenger) {
    private val binaryChannel = BasicMessageChannel(messenger, "my_hardware_plugin/camera/frames", BinaryCodec.INSTANCE)
    
    private var cameraDevice: CameraDevice? = null
    private var imageReader: ImageReader? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    fun start() {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        if (manager.cameraIdList.isEmpty()) return
        
        val cameraId = manager.cameraIdList[0]
        backgroundThread = HandlerThread("CameraModuleThread").apply { start() }
        backgroundHandler = Handler(backgroundThread!!.looper)

        // Using small resolution for demonstration; adjustable for production
        imageReader = ImageReader.newInstance(640, 480, ImageFormat.YUV_420_888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            if (image != null) {
                // Efficiently send bytes via binary channel
                val buffer = image.planes[0].buffer 
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                
                // Directly send binary blob to Dart (No JSON serialization)
                binaryChannel.send(ByteBuffer.wrap(bytes))
                image.close()
            }
        }, backgroundHandler)

        manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
            override fun onOpened(camera: CameraDevice) {
                cameraDevice = camera
                val surface = imageReader!!.surface
                val builder = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                builder.addTarget(surface)
                camera.createCaptureSession(listOf(surface), object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        session.setRepeatingRequest(builder.build(), null, backgroundHandler)
                    }
                    override fun onConfigureFailed(session: CameraCaptureSession) {}
                }, backgroundHandler)
            }
            override fun onDisconnected(camera: CameraDevice) { stop() }
            override fun onError(camera: CameraDevice, error: Int) { stop() }
        }, backgroundHandler)
    }

    fun stop() {
        cameraDevice?.close()
        imageReader?.close()
        backgroundThread?.quitSafely()
        cameraDevice = null
        imageReader = null
    }
}
