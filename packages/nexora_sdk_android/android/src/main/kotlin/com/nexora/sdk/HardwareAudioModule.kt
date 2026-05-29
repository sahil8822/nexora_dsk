package com.nexora.sdk

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
 * Improved with safety checks to prevent uninitialized stop crashes.
 */
class HardwareAudioModule(private val context: Context) {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var eventSink: EventChannel.EventSink? = null
    private var sampleRate = 44100
    private var bufferSize = 1024
    private var audioSource = MediaRecorder.AudioSource.MIC
    
    private var fftEnabled = false
    private var streamBytes = false
    private var updateIntervalMs = 80L
    private var lastEventMs = 0L
    private var noise: Noise? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun configure(options: Map<String, Any?>) {
        audioSource = when (options["source"] as? String ?: "mic") {
            "camcorder" -> MediaRecorder.AudioSource.CAMCORDER
            "voiceRecognition" -> MediaRecorder.AudioSource.VOICE_RECOGNITION
            "voiceCommunication" -> MediaRecorder.AudioSource.VOICE_COMMUNICATION
            else -> MediaRecorder.AudioSource.MIC
        }
        sampleRate = (options["sampleRate"] as? Number)?.toInt()
            ?: (options["preferredSampleRate"] as? Number)?.toInt()
            ?: sampleRate
        bufferSize = (options["bufferSize"] as? Number)?.toInt()
            ?.coerceAtLeast(256)
            ?: bufferSize
    }

    @SuppressLint("MissingPermission")
    fun start(enableFFT: Boolean = false, streamBytes: Boolean = false, updateIntervalMs: Int = 80): Boolean {
        if (isRecording) return true
        this.fftEnabled = enableFFT
        this.streamBytes = streamBytes
        this.updateIntervalMs = updateIntervalMs.coerceIn(16, 1000).toLong()
        this.lastEventMs = 0L
        
        if (fftEnabled) {
            noise = Noise.real(bufferSize)
        }

        try {
            audioRecord = AudioRecord(
                audioSource,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize * 2
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord?.release()
                audioRecord = null
                return false
            }

            isRecording = true
            audioRecord?.startRecording()

            Thread {
                val audioBuffer = ShortArray(bufferSize)
                val fftDst = FloatArray(bufferSize + 2)
                
                while (isRecording) {
                    val currentRecord = audioRecord ?: break
                    val read = currentRecord.read(audioBuffer, 0, bufferSize) ?: 0
                    if (read > 0) {
                        val now = android.os.SystemClock.elapsedRealtime()
                        if (now - lastEventMs < this.updateIntervalMs) continue
                        lastEventMs = now

                        var spectrum: FloatArray? = null
                        
                        if (fftEnabled && noise != null) {
                            val floatBuffer = FloatArray(bufferSize)
                            for (i in 0 until read) floatBuffer[i] = audioBuffer[i].toFloat()
                            noise?.fft(floatBuffer, fftDst)
                            
                            val magnitudes = FloatArray(bufferSize / 2)
                            for (i in 0 until (bufferSize / 2)) {
                                val real = fftDst[i * 2]
                                val imag = fftDst[i * 2 + 1]
                                magnitudes[i] = Math.sqrt((real * real + imag * imag).toDouble()).toFloat() / 1000
                            }
                            spectrum = magnitudes
                        }

                        var byteBuffer: ByteArray? = null
                        if (streamBytes) {
                            val bytes = ByteArray(read * 2)
                            for (i in 0 until read) {
                                bytes[i*2] = (audioBuffer[i].toInt() and 0xff).toByte()
                                bytes[i*2+1] = (audioBuffer[i].toInt() shr 8 and 0xff).toByte()
                            }
                            byteBuffer = bytes
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
        } catch (e: Exception) {
            audioRecord?.release()
            audioRecord = null
            return false
        }
    }

    fun stop() {
        isRecording = false
        try {
            // Only call stop if initialized and recording
            if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                audioRecord?.stop()
            }
        } catch (e: Exception) {
            // Log or ignore
        } finally {
            audioRecord?.release()
            audioRecord = null
        }
    }
}
