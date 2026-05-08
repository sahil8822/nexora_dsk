import AVFoundation
import Flutter
import Accelerate
import QuartzCore

/**
 * iOS Audio Manager with Native FFT Analysis (Accelerate Framework).
 */
public class HardwareAudioManager {
    private let audioEngine = AVAudioEngine()
    private var eventSink: FlutterEventSink?
    private var fftEnabled = false
    private var streamBytes = false
    private var updateIntervalMs = 80.0
    private var lastEventTime = CACurrentMediaTime()
    
    // FFT Vars
    private let fftSize = 1024
    private lazy var fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(fftSize))), FFTRadix(kFFTRadix2))

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }
    public func setFFTEnabled(_ enabled: Bool) { self.fftEnabled = enabled }
    public func setStreamBytes(_ enabled: Bool) { self.streamBytes = enabled }
    public func setUpdateIntervalMs(_ interval: Int) {
        self.updateIntervalMs = Double(max(16, min(interval, 1000)))
    }

    public func start() -> Bool {
        if audioEngine.isRunning { return true }
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(fftSize), format: format) { (buffer, _) in
            self.processAudio(buffer)
        }
        
        do {
            try audioEngine.start()
            return true
        } catch { return false }
    }

    private func processAudio(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        let now = CACurrentMediaTime()
        guard (now - lastEventTime) * 1000.0 >= updateIntervalMs else { return }
        lastEventTime = now
        
        var spectrum: [Float] = []
        if fftEnabled && frameCount >= fftSize {
            spectrum = calculateFFT(channelData)
        }

        var frame: [String: Any] = [
            "spectrum": spectrum,
            "sampleRate": Int(buffer.format.sampleRate)
        ]
        if streamBytes {
            frame["bytes"] = FlutterStandardTypedData(bytes: Data(bytes: channelData, count: frameCount * MemoryLayout<Float>.size))
        }
        let audioData: [String: Any] = [
            "module": "audio", "type": "data",
            "data": frame
        ]
        DispatchQueue.main.async { self.eventSink?(audioData) }
    }

    private func calculateFFT(_ data: UnsafeMutablePointer<Float>) -> [Float] {
        var real = [Float](repeating: 0.0, count: fftSize / 2)
        var imag = [Float](repeating: 0.0, count: fftSize / 2)
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
        
        data.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { 
            vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
        }
        
        vDSP_fft_zrip(fftSetup!, &splitComplex, 1, vDSP_Length(log2(Double(fftSize))), FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        return magnitudes
    }

    public func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
}
