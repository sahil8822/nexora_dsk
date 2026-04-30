import AVFoundation
import Flutter
import Accelerate

/**
 * iOS Audio Manager with Native FFT Analysis (Accelerate Framework).
 */
public class HardwareAudioManager {
    private let audioEngine = AVAudioEngine()
    private var eventSink: FlutterEventSink?
    private var fftEnabled = false
    
    // FFT Vars
    private let fftSize = 1024
    private lazy var fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(fftSize))), FFTRadix(kFFTRadix2))

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }
    public func setFFTEnabled(_ enabled: Bool) { self.fftEnabled = enabled }

    public func start() -> Bool {
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
        
        var spectrum: [Float] = []
        if fftEnabled && frameCount >= fftSize {
            spectrum = calculateFFT(channelData)
        }

        let data = Data(bytes: channelData, count: frameCount * MemoryLayout<Float>.size)
        let audioData: [String: Any] = [
            "module": "audio", "type": "data",
            "data": [
                "bytes": FlutterStandardTypedData(bytes: data),
                "spectrum": spectrum,
                "sampleRate": Int(buffer.format.sampleRate)
            ]
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
