package com.nexora.sdk

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.nexora.sdk.pigeon.NexoraAiResult
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class HardwareAiManager(private val context: Context) {
    private var interpreter: Interpreter? = null

    // ==================== Custom TF Lite Model ====================

    fun loadCustomModel(modelPath: String): Boolean {
        return try {
            val options = Interpreter.Options().apply {
                setNumThreads(4)
            }
            val file = File(modelPath)
            if (file.exists()) {
                interpreter = Interpreter(file, options)
                true
            } else {
                val assetPath = if (modelPath.startsWith("assets/")) modelPath else "flutter_assets/$modelPath"
                try {
                    val fileDescriptor = context.assets.openFd(assetPath)
                    val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
                    val fileChannel = inputStream.channel
                    val startOffset = fileDescriptor.startOffset
                    val declaredLength = fileDescriptor.declaredLength
                    val buffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
                    interpreter = Interpreter(buffer, options)
                    true
                } catch (assetEx: Exception) {
                    val stream = context.assets.open(assetPath)
                    val bytes = stream.readBytes()
                    val buffer = ByteBuffer.allocateDirect(bytes.size).apply {
                        order(ByteOrder.nativeOrder())
                        put(bytes)
                        rewind()
                    }
                    interpreter = Interpreter(buffer, options)
                    true
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    fun runInference(inputBuffer: ByteBuffer): Map<String, Any>? {
        val interp = interpreter ?: return null
        
        // This is a naive stub for arbitrary dynamic models. In a real TF Lite 
        // production app, you map exact shapes. We'll simulate execution logic.
        val outputBuffer = ByteBuffer.allocateDirect(4) 
        try {
            interp.run(inputBuffer, outputBuffer)
            return mapOf("success" to true)
        } catch (e: Exception) {
            return null
        }
    }

    // ==================== ML Kit Vision APIs ====================

    fun processFaceDetection(imageBytes: ByteArray, callback: (List<NexoraAiResult>) -> Unit) {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: run {
            callback(emptyList())
            return
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            .build()
            
        val detector = FaceDetection.getClient(options)
        
        detector.process(image)
            .addOnSuccessListener { faces ->
                val results = faces.map { face ->
                    NexoraAiResult(
                        label = "Face",
                        confidence = face.smilingProbability?.toDouble() ?: 1.0,
                        boundingBox = mapOf(
                            "top" to face.boundingBox.top.toDouble(),
                            "left" to face.boundingBox.left.toDouble(),
                            "width" to face.boundingBox.width().toDouble(),
                            "height" to face.boundingBox.height().toDouble()
                        ),
                        recognizedText = null
                    )
                }
                callback(results)
            }
            .addOnFailureListener {
                callback(emptyList())
            }
    }

    fun processBarcodeScanning(imageBytes: ByteArray, callback: (List<NexoraAiResult>) -> Unit) {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: run {
            callback(emptyList())
            return
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        
        val options = BarcodeScannerOptions.Builder().build() // All formats
        val scanner = BarcodeScanning.getClient(options)
        
        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                val results = barcodes.map { barcode ->
                    NexoraAiResult(
                        label = "Barcode (${barcode.format})",
                        confidence = 1.0,
                        boundingBox = barcode.boundingBox?.let { rect ->
                            mapOf(
                                "top" to rect.top.toDouble(),
                                "left" to rect.left.toDouble(),
                                "width" to rect.width().toDouble(),
                                "height" to rect.height().toDouble()
                            )
                        },
                        recognizedText = barcode.rawValue
                    )
                }
                callback(results)
            }
            .addOnFailureListener {
                callback(emptyList())
            }
    }

    fun processTextRecognition(imageBytes: ByteArray, callback: (List<NexoraAiResult>) -> Unit) {
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: run {
            callback(emptyList())
            return
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        
        recognizer.process(image)
            .addOnSuccessListener { text ->
                val results = text.textBlocks.map { block ->
                    NexoraAiResult(
                        label = "TextBlock",
                        confidence = 1.0,
                        boundingBox = block.boundingBox?.let { rect ->
                            mapOf(
                                "top" to rect.top.toDouble(),
                                "left" to rect.left.toDouble(),
                                "width" to rect.width().toDouble(),
                                "height" to rect.height().toDouble()
                            )
                        },
                        recognizedText = block.text
                    )
                }
                callback(results)
            }
            .addOnFailureListener {
                callback(emptyList())
            }
    }
}
