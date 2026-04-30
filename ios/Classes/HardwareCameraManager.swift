import UIKit
import AVFoundation
import Flutter
import Vision

/**
 * Ultra-Performance iOS Camera.
 * Implements FlutterTexture for direct GPU rendering.
 */
public class HardwareCameraManager: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var eventSink: FlutterEventSink?
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue", qos: .userInteractive)
    
    private var latestPixelBuffer: CVPixelBuffer?
    private var faceEnabled = false
    private var barcodeEnabled = false

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }
    
    public func setVisionMode(face: Bool, barcode: Bool) {
        self.faceEnabled = face
        self.barcodeEnabled = barcode
    }

    public func start(width: Int = 640, height: Int = 480) {
        if captureSession?.isRunning == true { return }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        captureSession?.beginConfiguration()
        if captureSession?.canAddInput(input) == true { captureSession?.addInput(input) }
        if captureSession?.canAddOutput(output) == true { captureSession?.addOutput(output) }
        captureSession?.commitConfiguration()
        
        captureSession?.startRunning()
    }

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let buffer = latestPixelBuffer else { return nil }
        return Unmanaged.passRetained(buffer)
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestPixelBuffer = pixelBuffer
        
        // Vision AI processing
        if faceEnabled || barcodeEnabled {
            let visionData = processVision(sampleBuffer)
            if let data = visionData {
                let event: [String: Any] = ["module": "camera", "type": "data", "data": ["vision": data]]
                DispatchQueue.main.async { self.eventSink?(event) }
            }
        }
    }

    private func processVision(_ buffer: CMSampleBuffer) -> [String: Any]? {
        let handler = VNImageRequestHandler(cmSampleBuffer: buffer, options: [:])
        var results: [String: Any] = [:]
        
        if faceEnabled {
            let request = VNDetectFaceRectanglesRequest()
            try? handler.perform([request])
            results["faces"] = request.results?.map { _ in ["top": 0.0, "left": 0.0] } ?? []
        }
        
        if barcodeEnabled {
            let request = VNDetectBarcodesRequest()
            try? handler.perform([request])
            results["barcodes"] = request.results?.map { $0.payloadStringValue ?? "" } ?? []
        }
        
        return results.isEmpty ? nil : results
    }

    public func stop() {
        captureSession?.stopRunning()
        captureSession = nil
        latestPixelBuffer = nil
    }
}
