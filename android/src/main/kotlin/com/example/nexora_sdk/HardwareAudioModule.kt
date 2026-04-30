package com.example.nexora_sdk

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import com.paramsen.noise.Noise

/**
 * High-performance Audio recording with Native FFT Analysis.
 */
class HardwareAudioModule(private val context: Context) {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var eventSink: EventChannel.EventSink? = null
    private val sampleRate = 44100
    private val bufferSize = 1024 // Power of 2 for FFT
    
    private var fftEnabled = false
    private var noise: Noise? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun start(enableFFT: Boolean = false): Boolean {
        if (isRecording) return true
        this.fftEnabled = enableFFT
        
        if (fftEnabled) {
            // Updated API usage for paramsen/noise
            noise = Noise.real(bufferSize)
        }

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize * 2
        )

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) return false

        isRecording = true
        audioRecord?.startRecording()

        Thread {
            val audioBuffer = ShortArray(bufferSize)
            val fftDst = FloatArray(bufferSize + 2) // Required size for destination
            
            while (isRecording) {
                val read = audioRecord?.read(audioBuffer, 0, bufferSize) ?: 0
                if (read > 0) {
                    var spectrum: FloatArray? = null
                    
                    if (fftEnabled && noise != null) {
                        val floatBuffer = FloatArray(bufferSize)
                        for (i in 0 until read) floatBuffer[i] = audioBuffer[i].toFloat()
                        
                        // Execute FFT with correct destination buffer
                        noise?.fft(floatBuffer, fftDst)
                        
                        // We only send the magnitudes (first half of the result)
                        val magnitudes = FloatArray(bufferSize / 2)
                        for (i in 0 until (bufferSize / 2)) {
                            val real = fftDst[i * 2]
                            val imag = fftDst[i * 2 + 1]
                            magnitudes[i] = Math.sqrt((real * real + imag * imag).toDouble()).toFloat() / 1000 // Normalize
                        }
                        spectrum = magnitudes
                    }

                    // Convert short array to byte array for Flutter
                    val byteBuffer = ByteArray(read * 2)
                    for (i in 0 until read) {
                        byteBuffer[i*2] = (audioBuffer[i].toInt() and 0xff).toByte()
                        byteBuffer[i*2+1] = (audioBuffer[i].toInt() shr 8 and 0xff).toByte()
                    }

                    val audioData = mapOf(
                        "module" to "audio",
                        "type" to "data",
                        "data" to mapOf(
                            "bytes" to byteBuffer,
                            "sampleRate" to sampleRate,
                            "spectrum" to spectrum?.toList()
                        )
                    )
                    Handler(Looper.getMainLooper()).post {
                        try { eventSink?.success(audioData) } catch (e: Exception) {}
                    }
                }
            }
        }.start()

        return true
    }

    fun stop() {
        isRecording = false
        audioRecord?.stop(); audioRecord?.release()
        audioRecord = null
    }
}
