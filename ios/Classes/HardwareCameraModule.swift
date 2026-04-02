import Flutter
import UIKit
import AVFoundation

/**
 * Performance-optimized iOS Camera module.
 * Streams raw binary pixel data directly via FlutterBasicMessageChannel.
 */
public class HardwareCameraModule: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var binaryChannel: FlutterBasicMessageChannel?
    private var captureSession: AVCaptureSession?
    private let videoOutputQueue = DispatchQueue(label: "camera.modular.queue")

    public init(messenger: FlutterBinaryMessenger) {
        self.binaryChannel = FlutterBasicMessageChannel(name: "my_hardware_plugin/camera/frames", binaryMessenger: messenger, codec: FlutterBinaryCodec())
    }

    public func start() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        captureSession?.addInput(input)
        captureSession?.addOutput(output)
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
        let height = CVPixelBufferGetHeight(imageBuffer)
        let totalBytes = bytesPerRow * height
        
        let data = Data(bytes: baseAddress!, count: totalBytes)
        
        // Zero-copy-like transfer of raw bytes via BasicMessageChannel
        binaryChannel?.sendMessage(data)
    }
}
