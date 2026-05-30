import Cocoa
import FlutterMacOS
import LocalAuthentication
import CoreBluetooth
import AVFoundation

public class NexoraSdkPlugin: NSObject, FlutterPlugin, 
    HardwareApi,
    AudioApi,
    LocationApi,
    SensorApi,
    BiometricsApi,
    BluetoothApi,
    SecureStorageApi,
    SystemApi,
    CryptoApi,
    AiApi {
    
    private let bluetooth = HardwareBluetoothManager()
    private let biometrics = HardwareBiometricManager()
    private let camera = HardwareCameraManager()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NexoraSdkPlugin()
        instance.camera.setTextureRegistry(registrar.textures)
        
        HardwareApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        AudioApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        LocationApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        SensorApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        BiometricsApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        BluetoothApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        SecureStorageApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        SystemApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        CryptoApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
        AiApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
    }

    // --- HardwareApi ---
    public func startCameraPreview(options: NexoraCameraOptions, completion: @escaping (Result<Int64, Error>) -> Void) {
        camera.start(options: options) { textureId in
            if let id = textureId {
                completion(.success(id))
            } else {
                completion(.failure(NSError(domain: "Camera", code: 0, userInfo: nil)))
            }
        }
    }
    
    public func stopCameraPreview(completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.stop()
        completion(.success(true))
    }
    
    public func takePicture(completion: @escaping (Result<String, Error>) -> Void) {
        completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil)))
    }
    
    public func switchCamera(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    public func setFlashMode(mode: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    // --- BluetoothApi ---
    public func startBluetoothScan(completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.startScan()
        completion(.success(true))
    }
    
    public func stopBluetoothScan(completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.stopScan()
        completion(.success(true))
    }
    
    public func connectToDevice(deviceId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.connect(deviceId: deviceId)
        completion(.success(true))
    }
    
    public func disconnectDevice(deviceId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.disconnect(deviceId: deviceId)
        completion(.success(true))
    }
    
    public func getConnectedDevices(completion: @escaping (Result<[String?], Error>) -> Void) {
        completion(.success(bluetooth.getConnectedDevices()))
    }
    
    public func sendData(deviceId: String, serviceUuid: String, characteristicUuid: String, data: FlutterStandardTypedData, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(bluetooth.sendData(deviceId: deviceId, data: data.data)))
    }
    
    public func readData(deviceId: String, serviceUuid: String, characteristicUuid: String, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
        completion(.success(nil))
    }
    
    public func readRssi(deviceId: String, completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(0))
    }

    // --- BiometricsApi ---
    public func canAuthenticate(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(biometrics.canAuthenticate()))
    }
    
    public func authenticateWithOptions(options: BiometricPromptOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        biometrics.authenticate(reason: options.localizedReason ?? "Authenticate") { success in
            completion(.success(success))
        }
    }
    
    // --- Unimplemented Fallbacks for required Pigeon protocols ---
    public func startAudioRecording(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopAudioRecording(completion: @escaping (Result<String, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func getAudioAmplitude(completion: @escaping (Result<Double, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func playAudio(filePath: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopAudioPlayback(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    
    public func getCurrentLocation(completion: @escaping (Result<NexoraLocation, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func startLocationUpdates(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopLocationUpdates(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double, completion: @escaping (Result<Double, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    
    public func getAccelerometerData(completion: @escaping (Result<[Double?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func getGyroscopeData(completion: @escaping (Result<[Double?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func getMagnetometerData(completion: @escaping (Result<[Double?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func startSensorStream(intervalMs: Int64, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopSensorStream(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    
    public func writeData(key: String, value: String, isEncrypted: Bool, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func readData(key: String, isEncrypted: Bool, completion: @escaping (Result<String?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func deleteData(key: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func clearAll(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    
    public func getBatteryLevel(completion: @escaping (Result<Int64, Error>) -> Void) { completion(.success(100)) }
    public func getNetworkType(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("wifi")) }
    public func isConnected(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.success(true)) }
    public func getAppVersion(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("1.0.0")) }
    public func getBuildNumber(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("1")) }
    public func getDeviceModel(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("Mac")) }
    public func getOsVersion(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("macOS")) }
    public func getDiskSpaceInfo(completion: @escaping (Result<[String? : Int64?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func getMemoryInfo(completion: @escaping (Result<[String? : Int64?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func openSettings(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func setScreenBrightness(brightness: Double, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func keepScreenOn(keepOn: Bool, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func vibrate(durationMs: Int64, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func hasHardwareFeature(feature: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func requestPermissions(permissions: [String?], completion: @escaping (Result<[String? : Bool?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func checkPermission(permission: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func showToast(message: String, duration: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func copyToClipboard(text: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func pasteText(completion: @escaping (Result<String?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func openUrl(url: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func shareText(text: String, subject: String?, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func saveToGallery(filePath: String, completion: @escaping (Result<String?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func enterPictureInPicture(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func getConnectedUsbDevices(completion: @escaping (Result<[String?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func startForegroundService(title: String, content: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func updateForegroundService(title: String, text: String, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopForegroundService(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func enableSmartSync(uploadEndpointUrl: String, headers: [String? : String?], rollLimitBytes: Int64, requireWifi: Bool, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func setEcoModeEnabled(enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) { completion(.success(())) }
    public func isEcoModeActive(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.success(false)) }
    public func getThermalState(completion: @escaping (Result<String, Error>) -> Void) { completion(.success("normal")) }
    public func startBackgroundSync(intervalMinutes: Int64, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func stopBackgroundSync(completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func generateBiometricKey(options: NexoraCryptoKeyOptions, completion: @escaping (Result<Bool, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func signWithBiometricKey(alias: String, payload: FlutterStandardTypedData, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func encryptWithBiometricKey(alias: String, plaintext: FlutterStandardTypedData, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func decryptWithBiometricKey(alias: String, ciphertext: FlutterStandardTypedData, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func processImageWithFaceDetection(imageBytes: FlutterStandardTypedData, completion: @escaping (Result<[NexoraAiResult?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func processImageWithBarcodeScanning(imageBytes: FlutterStandardTypedData, completion: @escaping (Result<[NexoraAiResult?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func processImageWithTextRecognition(imageBytes: FlutterStandardTypedData, completion: @escaping (Result<[NexoraAiResult?], Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
    public func runCustomModelInference(modelPath: String, inputBytes: FlutterStandardTypedData, completion: @escaping (Result<[String? : Any?]?, Error>) -> Void) { completion(.failure(NSError(domain: "Unsupported", code: -1, userInfo: nil))) }
}
