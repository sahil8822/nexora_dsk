import UIKit
import AVFoundation
import Flutter

/**
 * Production-grade iOS Camera subsystem using AVFoundation.
 * Streams raw pixel data to Flutter in the background.
 */
public class HardwareCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var eventSink: FlutterEventSink?
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    
    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    public func start() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        captureSession?.addInput(input)
        captureSession?.addOutput(output)
        
        // Final pixel format: 32BGRA
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        captureSession?.startRunning()
    }
    
    public func stop() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let bufferSize = bytesPerRow * height
        let data = Data(bytes: baseAddress!, count: bufferSize)
        
        let frameData: [String: Any] = [
            "type": "camera",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "data": [
                "bytes": FlutterStandardTypedData(bytes: data),
                "width": width,
                "height": height,
                "format": "bgra"
            ]
        ]
        
        DispatchQueue.main.async {
            self.eventSink?(frameData)
        }
    }
}
