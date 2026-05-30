import CoreML
import Vision
import Foundation
import MLKitFaceDetection
import MLKitBarcodeScanning
import MLKitTextRecognition
import MLKitVision

class HardwareAiManager {
    var model: VNCoreMLModel?
    
    // ==================== Custom CoreML Model ====================
    
    func loadCustomModel(modelPath: String) -> Bool {
        do {
            let url = URL(fileURLWithPath: modelPath)
            let compiledUrl = try MLModel.compileModel(at: url)
            let mlModel = try MLModel(contentsOf: compiledUrl)
            self.model = try VNCoreMLModel(for: mlModel)
            return true
        } catch {
            return false
        }
    }
    
    func runInference(inputData: Data) -> [String: Any]? {
        let start = Date()
        
        // Generic stub for CoreML inference with raw bytes.
        let executionTime = Date().timeIntervalSince(start) * 1000
        
        return [
            "success": true,
            "executionTimeMs": Int(executionTime)
        ]
    }
    
    // ==================== ML Kit Vision APIs ====================
    
    func processFaceDetection(imageBytes: Data, completion: @escaping ([NexoraAiResult]) -> Void) {
        guard let uiImage = UIImage(data: imageBytes) else {
            completion([])
            return
        }
        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = uiImage.imageOrientation
        
        let options = FaceDetectorOptions()
        options.performanceMode = .fast
        options.landmarksMode = .all
        options.classificationMode = .all
        
        let faceDetector = FaceDetector.faceDetector(options: options)
        
        faceDetector.process(visionImage) { faces, error in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                completion([])
                return
            }
            
            let results: [NexoraAiResult] = faces.map { face in
                let result = NexoraAiResult()
                result.label = "Face"
                result.confidence = face.hasSmilingProbability ? NSNumber(value: face.smilingProbability) : 1.0
                result.boundingBox = [
                    "top": face.frame.origin.y,
                    "left": face.frame.origin.x,
                    "width": face.frame.size.width,
                    "height": face.frame.size.height
                ]
                return result
            }
            completion(results)
        }
    }
    
    func processBarcodeScanning(imageBytes: Data, completion: @escaping ([NexoraAiResult]) -> Void) {
        guard let uiImage = UIImage(data: imageBytes) else {
            completion([])
            return
        }
        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = uiImage.imageOrientation
        
        let format = BarcodeFormat.all
        let barcodeOptions = BarcodeScannerOptions(formats: format)
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        
        barcodeScanner.process(visionImage) { barcodes, error in
            guard error == nil, let barcodes = barcodes, !barcodes.isEmpty else {
                completion([])
                return
            }
            
            let results: [NexoraAiResult] = barcodes.map { barcode in
                let result = NexoraAiResult()
                result.label = "Barcode (\(barcode.format.rawValue))"
                result.confidence = 1.0
                result.recognizedText = barcode.rawValue
                result.boundingBox = [
                    "top": barcode.frame.origin.y,
                    "left": barcode.frame.origin.x,
                    "width": barcode.frame.size.width,
                    "height": barcode.frame.size.height
                ]
                return result
            }
            completion(results)
        }
    }
    
    func processTextRecognition(imageBytes: Data, completion: @escaping ([NexoraAiResult]) -> Void) {
        guard let uiImage = UIImage(data: imageBytes) else {
            completion([])
            return
        }
        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = uiImage.imageOrientation
        
        let textRecognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions())
        
        textRecognizer.process(visionImage) { resultText, error in
            guard error == nil, let text = resultText else {
                completion([])
                return
            }
            
            let results: [NexoraAiResult] = text.blocks.map { block in
                let result = NexoraAiResult()
                result.label = "TextBlock"
                result.confidence = 1.0
                result.recognizedText = block.text
                result.boundingBox = [
                    "top": block.frame.origin.y,
                    "left": block.frame.origin.x,
                    "width": block.frame.size.width,
                    "height": block.frame.size.height
                ]
                return result
            }
            completion(results)
        }
    }
}
