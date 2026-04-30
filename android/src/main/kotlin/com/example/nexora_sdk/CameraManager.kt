package com.example.nexora_sdk

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import io.flutter.plugin.common.EventChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions

/**
 * Ultra-Performance Camera Manager with manual thread safety audits.
 */
class HardwareCameraManager(private val context: Context) {
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var previewRequestBuilder: CaptureRequest.Builder? = null
    
    private var imageReader: ImageReader? = null
    private var previewSurface: Surface? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null

    private var currentCameraId: String = "0"
    private var isFlashOn: Boolean = false
    private var isStarting: Boolean = false

    // Intelligence
    private var visionFaceEnabled: Boolean = false
    private var visionBarcodeEnabled: Boolean = false
    private val barcodeScanner = BarcodeScanning.getClient()
    private val faceDetector = FaceDetection.getClient(FaceDetectorOptions.Builder()
        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
        .build())

    fun setEventSink(sink: EventChannel.EventSink?) { this.eventSink = sink }
    
    fun setVisionMode(face: Boolean, barcode: Boolean) {
        this.visionFaceEnabled = face
        this.visionBarcodeEnabled = barcode
    }

    @SuppressLint("MissingPermission")
    @Synchronized
    fun startWithSurface(surface: Surface, width: Int, height: Int) {
        if (isStarting || cameraDevice != null) return
        isStarting = true
        
        this.previewSurface = surface
        backgroundThread = HandlerThread("NexoraCameraThread").apply { start() }
        backgroundHandler = Handler(backgroundThread!!.looper)

        imageReader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            try {
                val image = reader.acquireLatestImage()
                if (image != null) {
                    if (visionFaceEnabled || visionBarcodeEnabled) {
                        processImageWithIntelligence(image)
                    }
                    image.close()
                }
            } catch (e: Exception) {}
        }, backgroundHandler)

        openCurrentCamera()
    }

    @SuppressLint("MissingPermission")
    private fun openCurrentCamera() {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            manager.openCamera(currentCameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    isStarting = false
                    startPreview()
                }
                override fun onDisconnected(camera: CameraDevice) { stop() }
                override fun onError(camera: CameraDevice, error: Int) { stop() }
            }, backgroundHandler)
        } catch (e: Exception) { isStarting = false }
    }

    private fun startPreview() {
        val camera = cameraDevice ?: return
        val targets = mutableListOf<Surface>()
        previewSurface?.let { targets.add(it) }
        imageReader?.surface?.let { targets.add(it) }

        try {
            previewRequestBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
            targets.forEach { previewRequestBuilder?.addTarget(it) }

            camera.createCaptureSession(targets, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    updatePreview()
                }
                override fun onConfigureFailed(session: CameraCaptureSession) {}
            }, backgroundHandler)
        } catch (e: Exception) {}
    }

    private fun updatePreview() {
        try {
            val builder = previewRequestBuilder ?: return
            builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            builder.set(CaptureRequest.FLASH_MODE, if (isFlashOn) CaptureRequest.FLASH_MODE_TORCH else CaptureRequest.FLASH_MODE_OFF)
            captureSession?.setRepeatingRequest(builder.build(), null, backgroundHandler)
        } catch (e: Exception) {}
    }

    private fun processImageWithIntelligence(image: android.media.Image) {
        val inputImage = InputImage.fromMediaImage(image, 0)
        if (visionBarcodeEnabled) {
            barcodeScanner.process(inputImage).addOnSuccessListener { barcodes ->
                sendVisionData(mapOf("barcodes" to barcodes.map { it.rawValue ?: "" }))
            }
        }
        if (visionFaceEnabled) {
            faceDetector.process(inputImage).addOnSuccessListener { faces ->
                sendVisionData(mapOf("faces" to faces.map { mapOf("top" to it.boundingBox.top, "left" to it.boundingBox.left) }))
            }
        }
    }

    private fun sendVisionData(vision: Map<String, Any>) {
        val data = mapOf("module" to "camera", "type" to "data", "data" to mapOf("vision" to vision))
        Handler(context.mainLooper).post { 
            try { eventSink?.success(data) } catch (e: Exception) {}
        }
    }

    @Synchronized
    fun stop() {
        isStarting = false
        try {
            captureSession?.stopRepeating()
            captureSession?.close()
            cameraDevice?.close()
            imageReader?.close()
            backgroundThread?.quitSafely()
        } catch (e: Exception) {}
        captureSession = null; cameraDevice = null; imageReader = null
    }
}
