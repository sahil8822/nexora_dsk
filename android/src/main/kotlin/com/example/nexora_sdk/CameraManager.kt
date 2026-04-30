package com.example.nexora_sdk

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import io.flutter.plugin.common.EventChannel

/**
 * High-performance Camera2 implementation.
 * Streams raw frames via EventChannel.
 */
class HardwareCameraManager(private val context: Context) {
    private var cameraDevice: CameraDevice? = null
    private var imageReader: ImageReader? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun start(width: Int = 640, height: Int = 480) {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = manager.cameraIdList[0] // Default to back camera

        backgroundThread = HandlerThread("CameraBackground").apply { start() }
        backgroundHandler = Handler(backgroundThread!!.looper)

        imageReader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            if (image != null) {
                // Process in background
                processImage(image)
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
            override fun onDisconnected(camera: CameraDevice) { camera.close() }
            override fun onError(camera: CameraDevice, error: Int) { camera.close() }
        }, backgroundHandler)
    }

    fun stop() {
        cameraDevice?.close()
        imageReader?.close()
        backgroundThread?.quitSafely()
        cameraDevice = null
        imageReader = null
    }

    private fun processImage(image: android.media.Image) {
        // High-Performance: Combine Y, U, V planes for full color support
        // YUV_420_888 to contiguous byte array
        val yBuffer = image.planes[0].buffer
        val uBuffer = image.planes[1].buffer
        val vBuffer = image.planes[2].buffer

        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()

        val bytes = ByteArray(ySize + uSize + vSize)

        // Bulk copies are faster than per-pixel access
        yBuffer.get(bytes, 0, ySize)
        vBuffer.get(bytes, ySize, vSize)
        uBuffer.get(bytes, ySize + vSize, uSize)

        val frameData = mapOf(
            "type" to "camera",
            "timestamp" to System.currentTimeMillis(),
            "data" to mapOf(
                "bytes" to bytes,
                "width" to image.width,
                "height" to image.height,
                "format" to "yuv420"
            )
        )
        
        Handler(context.mainLooper).post {
            try {
                eventSink?.success(frameData)
            } catch (e: Exception) {
                // Sink might be closed
            }
        }
    }
}
