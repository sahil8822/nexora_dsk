import Cocoa
import AVFoundation
import FlutterMacOS
import CoreVideo

class HardwareCameraManager: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var latestPixelBuffer: CVPixelBuffer?
    private var textureId: Int64 = -1
    private var textureRegistry: FlutterTextureRegistry?
    
    func setTextureRegistry(_ registry: FlutterTextureRegistry?) {
        self.textureRegistry = registry
    }
    
    func start(options: NexoraCameraOptions, completion: @escaping (Int64?) -> Void) {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            completion(nil)
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_queue"))
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        self.captureSession = session
        self.videoOutput = output
        
        if let registry = textureRegistry {
            self.textureId = registry.register(self)
        }
        
        session.startRunning()
        completion(self.textureId)
    }
    
    func stop() {
        captureSession?.stopRunning()
        if textureId != -1 {
            textureRegistry?.unregisterTexture(textureId)
            textureId = -1
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            self.latestPixelBuffer = pixelBuffer
            if textureId != -1 {
                textureRegistry?.textureFrameAvailable(textureId)
            }
        }
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = latestPixelBuffer {
            return Unmanaged.passRetained(buffer)
        }
        return nil
    }
}
