package com.nexora.sdk

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
import java.io.File
import java.io.FileOutputStream
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
    private var photoReader: ImageReader? = null
    private var previewSurface: Surface? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null

    private var currentCameraId: String = "0"
    private var isFlashOn: Boolean = false
    private var isStarting: Boolean = false
    private var lastWidth: Int = 640
    private var lastHeight: Int = 480
    private var lastSurface: Surface? = null
    private var lastVisionFrameMs: Long = 0

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
        lastWidth = width
        lastHeight = height
        lastSurface = surface
        
        this.previewSurface = surface
        backgroundThread = HandlerThread("NexoraCameraThread").apply { start() }
        backgroundHandler = Handler(backgroundThread!!.looper)

        imageReader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            try {
                val image = reader.acquireLatestImage()
                if (image != null) {
                    val now = android.os.SystemClock.elapsedRealtime()
                    if ((visionFaceEnabled || visionBarcodeEnabled) && now - lastVisionFrameMs >= 120) {
                        lastVisionFrameMs = now
                        processImageWithIntelligence(image)
                    }
                    image.close()
                }
            } catch (e: Exception) {}
        }, backgroundHandler)

        photoReader = ImageReader.newInstance(width, height, ImageFormat.JPEG, 1)

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
        photoReader?.surface?.let { targets.add(it) }

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

    fun setFlash(on: Boolean) {
        isFlashOn = on
        updatePreview()
    }

    fun setZoom(level: Float) {
        try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val characteristics = manager.getCameraCharacteristics(currentCameraId)
            val maxZoom = characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1f
            val clampedZoom = level.coerceIn(1f, maxZoom)
            val sensorRect = characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE) ?: return
            val cropW = (sensorRect.width() / clampedZoom).toInt()
            val cropH = (sensorRect.height() / clampedZoom).toInt()
            val cropX = (sensorRect.width() - cropW) / 2
            val cropY = (sensorRect.height() - cropH) / 2
            previewRequestBuilder?.set(CaptureRequest.SCALER_CROP_REGION, Rect(cropX, cropY, cropX + cropW, cropY + cropH))
            updatePreview()
        } catch (e: Exception) {}
    }

    fun takePhoto(fileName: String?, callback: (String?) -> Unit) {
        val camera = cameraDevice ?: run { callback(null); return }
        val session = captureSession ?: run { callback(null); return }
        val reader = photoReader ?: run { callback(null); return }
        val handler = backgroundHandler ?: run { callback(null); return }
        val outputFile = File(
            context.cacheDir,
            fileName?.takeIf { it.isNotBlank() } ?: "nexora_photo_${System.currentTimeMillis()}.jpg"
        )

        reader.setOnImageAvailableListener({ imageReader ->
            val image = imageReader.acquireNextImage() ?: return@setOnImageAvailableListener
            try {
                val buffer = image.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                FileOutputStream(outputFile).use { it.write(bytes) }
                Handler(context.mainLooper).post { callback(outputFile.absolutePath) }
            } catch (e: Exception) {
                Handler(context.mainLooper).post { callback(null) }
            } finally {
                image.close()
            }
        }, handler)

        try {
            val request = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            request.addTarget(reader.surface)
            request.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            request.set(CaptureRequest.FLASH_MODE, if (isFlashOn) CaptureRequest.FLASH_MODE_SINGLE else CaptureRequest.FLASH_MODE_OFF)
            session.capture(request.build(), null, handler)
        } catch (e: Exception) {
            callback(null)
        }
    }

    @Synchronized
    fun flipCamera() {
        val newId = if (currentCameraId == "0") "1" else "0"
        stop()
        currentCameraId = newId
        val surface = lastSurface
        if (surface != null) {
            startWithSurface(surface, lastWidth, lastHeight)
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
            photoReader?.close()
            backgroundThread?.quitSafely()
        } catch (e: Exception) {}
        captureSession = null; cameraDevice = null; imageReader = null; photoReader = null
    }
}
