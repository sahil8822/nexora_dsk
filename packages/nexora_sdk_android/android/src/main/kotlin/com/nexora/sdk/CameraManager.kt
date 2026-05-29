package com.nexora.sdk

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Range
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
    
    private var mediaRecorder: android.media.MediaRecorder? = null
    private var isRecordingVideo: Boolean = false
    private var videoFile: File? = null
    private var activeShader: String = "none"
    
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
    private var visionFrameIntervalMs: Long = 120
    private var targetFpsRange: Range<Int>? = null
    private var manualControls: Map<String, Any?> = emptyMap()

    // Intelligence
    private var visionFaceEnabled: Boolean = false
    private var visionBarcodeEnabled: Boolean = false
    private val barcodeScanner = BarcodeScanning.getClient()
    private val faceDetector = FaceDetection.getClient(FaceDetectorOptions.Builder()
        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
        .build())

    private var customModelAssetPath: String? = null
    private var customLabels: List<String>? = null
    private var customThreshold: Float = 0.5f
    private var isCustomClassifierRegistered: Boolean = false

    fun registerCustomClassifier(modelAssetPath: String, labels: List<String>, threshold: Float): Boolean {
        this.customModelAssetPath = modelAssetPath
        this.customLabels = labels
        this.customThreshold = threshold
        this.isCustomClassifierRegistered = true
        return true
    }

    fun setEventSink(sink: EventChannel.EventSink?) { this.eventSink = sink }

    fun configure(options: Map<String, Any?>) {
        val lens = options["lens"] as? String ?: "defaultLens"
        currentCameraId = findCameraIdForLens(lens) ?: currentCameraId
        targetFpsRange = fpsRangeFor(options["fps"] as? String, currentCameraId)
        manualControls = options["manualControls"] as? Map<String, Any?> ?: emptyMap()
        visionFrameIntervalMs = when (options["visionPerformanceMode"] as? String) {
            "accurate" -> 220L
            "fast" -> 80L
            else -> 120L
        }
    }
    
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
                    if ((visionFaceEnabled || visionBarcodeEnabled) &&
                        now - lastVisionFrameMs >= visionFrameIntervalMs
                    ) {
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
            targetFpsRange?.let {
                builder.set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, it)
            }
            applyManualControls(builder)
            builder.set(CaptureRequest.FLASH_MODE, if (isFlashOn) CaptureRequest.FLASH_MODE_TORCH else CaptureRequest.FLASH_MODE_OFF)
            applyActiveShaderToRequest(builder)
            captureSession?.setRepeatingRequest(builder.build(), null, backgroundHandler)
        } catch (e: Exception) {}
    }

    private fun applyManualControls(builder: CaptureRequest.Builder) {
        val focusDistance = (manualControls["focusDistance"] as? Number)?.toFloat()
        if (focusDistance != null) {
            builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_OFF)
            builder.set(CaptureRequest.LENS_FOCUS_DISTANCE, focusDistance.coerceAtLeast(0f))
        }

        val exposureTime = (manualControls["exposureTime"] as? Number)?.toLong()
        val iso = (manualControls["iso"] as? Number)?.toInt()
        if (exposureTime != null || iso != null) {
            builder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_OFF)
            exposureTime?.let { builder.set(CaptureRequest.SENSOR_EXPOSURE_TIME, it.coerceAtLeast(1L)) }
            iso?.let { builder.set(CaptureRequest.SENSOR_SENSITIVITY, it.coerceAtLeast(1)) }
        }

        val whiteBalance = manualControls["whiteBalanceMode"] as? String ?: return
        builder.set(CaptureRequest.CONTROL_AWB_MODE, whiteBalanceMode(whiteBalance))
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

    private fun findCameraIdForLens(lens: String): String? {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val preferredFacing = when (lens) {
            "front" -> CameraCharacteristics.LENS_FACING_FRONT
            "back", "ultraWide", "telephoto", "defaultLens" -> CameraCharacteristics.LENS_FACING_BACK
            else -> CameraCharacteristics.LENS_FACING_BACK
        }
        return manager.cameraIdList.firstOrNull { id ->
            val characteristics = manager.getCameraCharacteristics(id)
            characteristics.get(CameraCharacteristics.LENS_FACING) == preferredFacing
        }
    }

    private fun fpsRangeFor(fps: String?, cameraId: String): Range<Int>? {
        val value = when (fps) {
            "fps24" -> 24
            "fps30" -> 30
            "fps60" -> 60
            else -> return null
        }
        return try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val characteristics = manager.getCameraCharacteristics(cameraId)
            val ranges = characteristics.get(
                CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES
            ) ?: return null
            ranges.firstOrNull { it.lower == value && it.upper == value }
                ?: ranges.firstOrNull { it.lower <= value && it.upper >= value }
        } catch (_: Exception) {
            null
        }
    }

    private fun whiteBalanceMode(value: String): Int {
        return when (value) {
            "off", "locked" -> CaptureRequest.CONTROL_AWB_MODE_OFF
            "incandescent" -> CaptureRequest.CONTROL_AWB_MODE_INCANDESCENT
            "fluorescent" -> CaptureRequest.CONTROL_AWB_MODE_FLUORESCENT
            "warmFluorescent" -> CaptureRequest.CONTROL_AWB_MODE_WARM_FLUORESCENT
            "daylight" -> CaptureRequest.CONTROL_AWB_MODE_DAYLIGHT
            "cloudy" -> CaptureRequest.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT
            "twilight" -> CaptureRequest.CONTROL_AWB_MODE_TWILIGHT
            "shade" -> CaptureRequest.CONTROL_AWB_MODE_SHADE
            else -> CaptureRequest.CONTROL_AWB_MODE_AUTO
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

    @SuppressLint("MissingPermission")
    fun startVideoRecording(fileName: String?, callback: (String?) -> Unit) {
        if (cameraDevice == null || isRecordingVideo) {
            callback(null)
            return
        }

        val handler = backgroundHandler ?: run { callback(null); return }
        videoFile = File(
            context.cacheDir,
            fileName?.takeIf { it.isNotBlank() } ?: "nexora_video_${System.currentTimeMillis()}.mp4"
        )

        captureSession?.close()
        captureSession = null

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            android.media.MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            android.media.MediaRecorder()
        }
        mediaRecorder = recorder

        try {
            recorder.setAudioSource(android.media.MediaRecorder.AudioSource.MIC)
            recorder.setVideoSource(android.media.MediaRecorder.VideoSource.SURFACE)
            recorder.setOutputFormat(android.media.MediaRecorder.OutputFormat.MPEG_4)
            recorder.setOutputFile(videoFile!!.absolutePath)
            recorder.setVideoEncoder(android.media.MediaRecorder.VideoEncoder.H264)
            recorder.setAudioEncoder(android.media.MediaRecorder.AudioEncoder.AAC)
            recorder.setVideoSize(lastWidth, lastHeight)
            recorder.setVideoFrameRate(30)
            recorder.setVideoEncodingBitRate(5_000_000)
            recorder.setAudioEncodingBitRate(128_000)
            recorder.setAudioSamplingRate(44100)
            
            recorder.prepare()
        } catch (e: Exception) {
            recorder.release()
            mediaRecorder = null
            callback(null)
            startPreview()
            return
        }

        val targets = mutableListOf<Surface>()
        previewSurface?.let { targets.add(it) }
        imageReader?.surface?.let { targets.add(it) }
        targets.add(recorder.surface)

        try {
            previewRequestBuilder = cameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_RECORD)
            targets.forEach { previewRequestBuilder?.addTarget(it) }

            cameraDevice!!.createCaptureSession(targets, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    try {
                        val builder = previewRequestBuilder ?: return
                        builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                        builder.set(CaptureRequest.FLASH_MODE, if (isFlashOn) CaptureRequest.FLASH_MODE_TORCH else CaptureRequest.FLASH_MODE_OFF)
                        applyActiveShaderToRequest(builder)
                        session.setRepeatingRequest(builder.build(), null, backgroundHandler)
                        
                        recorder.start()
                        isRecordingVideo = true
                        Handler(context.mainLooper).post { callback(videoFile!!.absolutePath) }
                    } catch (e: Exception) {
                        Handler(context.mainLooper).post { callback(null) }
                    }
                }
                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Handler(context.mainLooper).post { callback(null) }
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            callback(null)
        }
    }

    fun stopVideoRecording(callback: (String?) -> Unit) {
        if (!isRecordingVideo || mediaRecorder == null) {
            callback(null)
            return
        }

        try {
            mediaRecorder?.stop()
        } catch (e: Exception) {}
        mediaRecorder?.reset()
        mediaRecorder?.release()
        mediaRecorder = null
        isRecordingVideo = false

        val path = videoFile?.absolutePath
        videoFile = null

        captureSession?.close()
        captureSession = null
        startPreview()

        callback(path)
    }

    fun applyCameraFilterShader(shaderType: String): Boolean {
        activeShader = shaderType.lowercase()
        updatePreview()
        return true
    }

    private fun applyActiveShaderToRequest(builder: CaptureRequest.Builder) {
        val effectMode = when (activeShader) {
            "sepia" -> CaptureRequest.CONTROL_EFFECT_MODE_SEPIA
            "monochrome", "mono" -> CaptureRequest.CONTROL_EFFECT_MODE_MONO
            "negative" -> CaptureRequest.CONTROL_EFFECT_MODE_NEGATIVE
            "blackboard" -> CaptureRequest.CONTROL_EFFECT_MODE_BLACKBOARD
            else -> CaptureRequest.CONTROL_EFFECT_MODE_OFF
        }
        builder.set(CaptureRequest.CONTROL_EFFECT_MODE, effectMode)
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
