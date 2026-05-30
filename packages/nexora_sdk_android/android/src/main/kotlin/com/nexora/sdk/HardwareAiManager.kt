package com.nexora.sdk

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class HardwareAiManager(private val context: Context) {
    private var interpreter: Interpreter? = null

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

    fun runInference(input: Map<String, Any>): Map<String, Any> {
        val interp = interpreter ?: return mapOf()
        val start = System.currentTimeMillis()
        
        val inputBuffer = ByteBuffer.allocateDirect(4) // Dummy size
        val outputBuffer = ByteBuffer.allocateDirect(4) // Dummy size
        
        try {
            interp.run(inputBuffer, outputBuffer)
        } catch (e: Exception) {}
        
        val executionTime = System.currentTimeMillis() - start
        
        return mapOf(
            "outputs" to mapOf("prediction" to listOf<Float>()),
            "executionTimeMs" to executionTime.toInt()
        )
    }

    fun runInferenceOnImage(bitmap: Bitmap): Pair<Int, Float>? {
        val interp = interpreter ?: return null
        return try {
            val inputTensor = interp.getInputTensor(0)
            val shape = inputTensor.shape() // [1, H, W, C]
            val height = shape[1]
            val width = shape[2]
            val channels = shape[3]
            
            val resized = Bitmap.createScaledBitmap(bitmap, width, height, true)
            val byteBuffer = ByteBuffer.allocateDirect(4 * width * height * channels).apply {
                order(ByteOrder.nativeOrder())
            }
            
            val intValues = IntArray(width * height)
            resized.getPixels(intValues, 0, width, 0, 0, width, height)
            
            byteBuffer.rewind()
            for (pixel in intValues) {
                val r = (pixel shr 16 and 0xFF)
                val g = (pixel shr 8 and 0xFF)
                val b = (pixel and 0xFF)
                
                byteBuffer.putFloat(r / 255f)
                byteBuffer.putFloat(g / 255f)
                if (channels >= 3) {
                    byteBuffer.putFloat(b / 255f)
                }
            }
            
            val outputTensor = interp.getOutputTensor(0)
            val outputShape = outputTensor.shape() // [1, num_classes]
            val numClasses = outputShape[1]
            val outputArray = Array(1) { FloatArray(numClasses) }
            
            interp.run(byteBuffer, outputArray)
            
            var maxIdx = -1
            var maxVal = -1f
            for (i in 0 until numClasses) {
                if (outputArray[0][i] > maxVal) {
                    maxVal = outputArray[0][i]
                    maxIdx = i
                }
            }
            
            if (maxIdx != -1) Pair(maxIdx, maxVal) else null
        } catch (e: Exception) {
            null
        }
    }
}
