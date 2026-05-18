import UIKit
import AVFoundation
import Flutter
import Vision
import QuartzCore

/// Ultra-Performance iOS Camera with full control (Flash, Zoom, Flip).
/// Implements FlutterTexture for direct GPU rendering.
public class HardwareCameraManager: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var photoDelegate: PhotoCaptureDelegate?
    private var eventSink: FlutterEventSink?
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue", qos: .userInteractive)
    
    private let bufferLock = NSLock()
    private var latestPixelBuffer: CVPixelBuffer?
    private var faceEnabled = false
    private var barcodeEnabled = false
    private var currentPosition: AVCaptureDevice.Position = .back
    private var lastWidth: Int = 640
    private var lastHeight: Int = 480
    private var lastVisionFrameTime = CACurrentMediaTime()

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }
    
    public func setVisionMode(face: Bool, barcode: Bool) {
        self.faceEnabled = face
        self.barcodeEnabled = barcode
    }

    public func start(width: Int = 1280, height: Int = 720) {
        if captureSession?.isRunning == true { return }
        lastWidth = width
        lastHeight = height

        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = width >= 1280 || height >= 720 ? .hd1280x720 : .vga640x480

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        currentDevice = device
        currentInput = input

        let output = AVCaptureVideoDataOutput()
        let photoOutput = AVCapturePhotoOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        captureSession?.beginConfiguration()
        if captureSession?.canAddInput(input) == true { captureSession?.addInput(input) }
        if captureSession?.canAddOutput(output) == true { captureSession?.addOutput(output) }
        if captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
            self.photoOutput = photoOutput
        }
        captureSession?.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    // MARK: - Camera Controls

    public func setFlash(on: Bool) {
        guard let device = currentDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {}
    }

    public func setZoom(level: Double) {
        guard let device = currentDevice else { return }
        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
        let clampedZoom = max(1.0, min(CGFloat(level), maxZoom))
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedZoom
            device.unlockForConfiguration()
        } catch {}
    }

    public func flipCamera() {
        stop()
        currentPosition = (currentPosition == .back) ? .front : .back
        start(width: lastWidth, height: lastHeight)
    }

    public func takePhoto(fileName: String?, completion: @escaping (String?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        let name = (fileName?.isEmpty == false ? fileName! : "nexora_photo_\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate(outputUrl: url) { [weak self] path in
            self?.photoDelegate = nil
            completion(path)
        }
        photoDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    // MARK: - FlutterTexture

    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        guard let buffer = latestPixelBuffer else { return nil }
        return Unmanaged.passRetained(buffer)
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.lock()
        latestPixelBuffer = pixelBuffer
        bufferLock.unlock()
        
        let now = CACurrentMediaTime()
        if (faceEnabled || barcodeEnabled) && now - lastVisionFrameTime >= 0.12 {
            lastVisionFrameTime = now
            let visionData = processVision(sampleBuffer)
            if let data = visionData {
                let event: [String: Any] = ["module": "camera", "type": "data", "data": ["vision": data]]
                DispatchQueue.main.async { self.eventSink?(event) }
            }
        }
    }

    private func processVision(_ buffer: CMSampleBuffer) -> [String: Any]? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        var results: [String: Any] = [:]
        
        if faceEnabled {
            let request = VNDetectFaceRectanglesRequest()
            try? handler.perform([request])
            results["faces"] = request.results?.map { face in
                ["top": face.boundingBox.origin.y, "left": face.boundingBox.origin.x]
            } ?? []
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
        currentDevice = nil
        currentInput = nil
        photoOutput = nil
        photoDelegate = nil
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let outputUrl: URL
    private let completion: (String?) -> Void

    init(outputUrl: URL, completion: @escaping (String?) -> Void) {
        self.outputUrl = outputUrl
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else {
            completion(nil)
            return
        }
        do {
            try data.write(to: outputUrl, options: .atomic)
            completion(outputUrl.path)
        } catch {
            completion(nil)
        }
    }
}
