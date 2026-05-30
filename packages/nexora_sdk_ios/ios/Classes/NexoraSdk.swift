import Flutter
import UIKit
import AVFoundation
import CoreLocation
import CoreBluetooth
import Network

/// Nexora SDK v3.1.2 — Complete iOS Plugin with type-safe Pigeon host APIs.
public class NexoraSdk: NSObject, FlutterPlugin, CLLocationManagerDelegate,
    HardwareApi,
    AudioApi,
    LocationApi,
    SensorApi,
    BiometricsApi,
    BluetoothApi,
    SecureStorageApi,
    SystemApi {

    private let camera = HardwareCameraManager()
    private let audio = HardwareAudioManager()
    private let sensors = HardwareSensorManager()
    private let bluetooth = HardwareBluetoothManager()
    private let blePeripheral = HardwareBlePeripheralManager()
    private let location = HardwareLocationManager()
    private let biometrics = HardwareBiometricManager()
    private let feedback = HardwareFeedbackManager()
    private let health = HardwareHealthManager()
    private let storage = HardwareStorageManager()
    private let nfc = HardwareNfcManager()
    private let ai = HardwareAiManager()
    private let crypto = HardwareCryptoManager()
    private let backgroundTasks = HardwareTaskManager()

    private var ecoModeUserEnabled = false
    private var sdkConfig: [String: Any] = [:]
    private var logNativeCalls = false
    private var iosOptions: [String: Any] = [:]
    
    private var registrar: FlutterPluginRegistrar?
    private var textureId: Int64 = -1
    private var permissionResult: ((Any?) -> Void)?
    private var permissionLocationManager: CLLocationManager?
    private var pendingCameraPermission = false
    private var pendingMicrophonePermission = false
    private var pendingPermissionType: String?
    private var eventSink: FlutterEventSink?

    public override init() {
        super.init()
        health.setSmartSyncManager(SmartSyncManager.shared)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NexoraSdk()
        instance.registrar = registrar

        // Register legacy MethodChannel for backward compatibility
        let channel = FlutterMethodChannel(name: "nexora_sdk/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "nexora_sdk/events", binaryMessenger: registrar.messenger())
        let streamHandler = InlineStreamHandler(sdk: instance)
        eventChannel.setStreamHandler(streamHandler)

        NotificationCenter.default.addObserver(
            instance,
            selector: #selector(instance.didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // Set up Pigeon host APIs
        HardwareApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        AudioApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        LocationApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        SensorApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        BiometricsApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        BluetoothApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        SecureStorageApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        SystemApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        releaseHardware()
    }

    class InlineStreamHandler: NSObject, FlutterStreamHandler {
        private weak var sdk: NexoraSdk?
        init(sdk: NexoraSdk) {
            self.sdk = sdk
        }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            sdk?.eventSink = events
            sdk?.camera.setEventSink(events)
            sdk?.bluetooth.setEventSink(events)
            sdk?.blePeripheral.setEventSink(events)
            sdk?.location.setEventSink(events)
            sdk?.sensors.setEventSink(events)
            sdk?.audio.setEventSink(events)
            sdk?.nfc.setEventSink(events)
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            sdk?.eventSink = nil
            sdk?.camera.setEventSink(nil)
            sdk?.bluetooth.setEventSink(nil)
            sdk?.blePeripheral.setEventSink(nil)
            sdk?.location.setEventSink(nil)
            sdk?.sensors.setEventSink(nil)
            sdk?.audio.setEventSink(nil)
            sdk?.nfc.setEventSink(nil)
            return nil
        }
    }

    @objc private func didReceiveMemoryWarning() {
        storage.clearCache()
        let warningData: [String: Any] = [
            "module": "system",
            "type": "memoryWarning",
            "data": [
                "warning": "LOW_MEMORY"
            ]
        ]
        DispatchQueue.main.async {
            self.eventSink?(warningData)
        }
    }

    // Legacy routing mapping (kept for binary backward compatibility)
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        if logNativeCalls {
            NSLog("NexoraSdk legacy call: \(call.method)")
        }

        switch call.method {
        case "configureSdk":
            sdkConfig = args ?? [:]
            logNativeCalls = sdkConfig["logNativeCalls"] as? Bool ?? false
            iosOptions = sdkConfig["ios"] as? [String: Any] ?? [:]
            applyIosOptions(iosOptions)
            result(true)
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "connectL2cap":
            let deviceId = args?["deviceId"] as? String ?? ""
            let psm = args?["psm"] as? Int ?? 0
            let success = bluetooth.connectL2cap(deviceId: deviceId, psm: psm)
            result(success)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func releaseHardware() {
        camera.stop()
        audio.stop()
        sensors.stop()
        location.stopUpdates()
        bluetooth.disconnect()
        health.stopLogging()
        if textureId != -1 {
            registrar?.textures().unregisterTexture(textureId)
            textureId = -1
        }
    }

    // ==================== Helper Permission Methods ====================
    private func requestCameraPermission(result: @escaping (Any?) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            result(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { result(granted) }
            }
        default:
            result(false)
        }
    }

    private func requestAudioPermission(result: @escaping (Any?) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            result(true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { result(granted) }
            }
        default:
            result(false)
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if CLLocationManager.authorizationStatus() == .notDetermined { return }
        finishNativePermissionRequest()
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined { return }
        finishNativePermissionRequest()
    }

    private func finishNativePermissionRequest() {
        guard let result = permissionResult else { return }
        let granted: Bool
        if pendingPermissionType == "location" {
            granted = hasLocationPermission()
        } else {
            granted = pendingCameraPermission && pendingMicrophonePermission && hasLocationPermission()
        }
        permissionResult = nil
        pendingPermissionType = nil
        permissionLocationManager?.delegate = nil
        permissionLocationManager = nil
        result(granted)
    }

    private func hasLocationPermission() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    private func hasBluetoothPermission() -> Bool {
        if #available(iOS 13.1, *) {
            return CBManager.authorization == .allowedAlways
        }
        return true
    }

    private func getPermissionStatus(type: String) -> [String: Any] {
        let permission = type
        let state: String
        let canRequest: Bool

        switch type {
        case "camera":
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                state = "granted"
                canRequest = false
            case .notDetermined:
                state = "notDetermined"
                canRequest = true
            case .denied:
                state = "permanentlyDenied"
                canRequest = false
            case .restricted:
                state = "restricted"
                canRequest = false
            @unknown default:
                state = "unsupported"
                canRequest = false
            }
        case "audio":
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                state = "granted"
                canRequest = false
            case .undetermined:
                state = "notDetermined"
                canRequest = true
            case .denied:
                state = "permanentlyDenied"
                canRequest = false
            @unknown default:
                state = "unsupported"
                canRequest = false
            }
        case "location":
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                state = "granted"
                canRequest = false
            case .notDetermined:
                state = "notDetermined"
                canRequest = true
            case .denied:
                state = "permanentlyDenied"
                canRequest = false
            case .restricted:
                state = "restricted"
                canRequest = false
            @unknown default:
                state = "unsupported"
                canRequest = false
            }
        case "bluetooth":
            if #available(iOS 13.1, *) {
                switch CBManager.authorization {
                case .allowedAlways:
                    state = "granted"
                    canRequest = false
                case .notDetermined:
                    state = "notDetermined"
                    canRequest = true
                case .denied:
                    state = "permanentlyDenied"
                    canRequest = false
                case .restricted:
                    state = "restricted"
                    canRequest = false
                @unknown default:
                    state = "unsupported"
                    canRequest = false
                }
            } else {
                state = "granted"
                canRequest = false
            }
        default:
            state = "unsupported"
            canRequest = false
        }

        return [
            "permission": permission,
            "state": state,
            "canRequest": canRequest
        ]
    }

    private func cameraSize(for resolution: String?) -> (width: Int, height: Int) {
        switch resolution {
        case "low":
            return (640, 480)
        case "medium":
            return (960, 540)
        case "fullHd":
            return (1920, 1080)
        default:
            return (1280, 720)
        }
    }

    private func applyIosOptions(_ options: [String: Any]) {
        let cameraOptions = options["camera"] as? [String: Any] ?? [:]
        camera.configure(options: cameraOptions)

        let rootAudio = sdkConfig["audio"] as? [String: Any] ?? [:]
        let audioOptions = options["audio"] as? [String: Any] ?? [:]
        audio.configure(options: rootAudio.merging(audioOptions) { _, new in new })

        let locationOptions = options["location"] as? [String: Any] ?? [:]
        location.configure(options: locationOptions)
        if let backgroundEnabled = locationOptions["allowsBackgroundLocationUpdates"] as? Bool {
            location.setBackgroundEnabled(backgroundEnabled)
        }

        let bluetoothOptions = options["bluetooth"] as? [String: Any] ?? [:]
        bluetooth.configure(options: bluetoothOptions)

        let sensorOptions = options["sensors"] as? [String: Any] ?? [:]
        sensors.configure(options: sensorOptions)

        let biometricOptions = options["biometrics"] as? [String: Any] ?? [:]
        biometrics.configure(options: biometricOptions)

        let systemOptions = options["system"] as? [String: Any] ?? [:]
        UIApplication.shared.isIdleTimerDisabled =
            systemOptions["keepScreenOn"] as? Bool ?? false
    }

    private func cpuArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #elseif arch(arm)
        return "arm"
        #else
        return "unknown"
        #endif
    }

    // ==================== HardwareApi Implementation ====================
    public func startCamera(width: Int64, height: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Camera permission is required.", details: nil)))
            return
        }
        textureId = registrar?.textures().register(camera) ?? -1
        camera.start(width: Int(width), height: Int(height))
        completion(.success(textureId))
    }

    public func startCameraWithOptions(options: NexoraCameraOptions, completion: @escaping (Result<Int64, Error>) -> Void) {
        textureId = registrar?.textures().register(camera) ?? -1
        let size = cameraSize(for: options.resolution)
        camera.start(width: size.width, height: size.height)
        completion(.success(textureId))
    }

    public func stopCamera(completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.stop()
        if textureId != -1 {
            registrar?.textures().unregisterTexture(textureId)
        }
        textureId = -1
        completion(.success(true))
    }

    public func setVisionMode(options: VisionModeOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.setVisionMode(face: options.face ?? false, barcode: options.barcode ?? false)
        completion(.success(true))
    }

    public func registerCustomClassifier(options: CustomClassifierOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let modelAssetPath = options.modelAssetPath,
              let labels = options.labels?.compactMap({ $0 }) else {
            completion(.failure(PigeonError(code: "INVALID_ARGUMENT", message: "registerCustomClassifier requires modelAssetPath and labels.", details: nil)))
            return
        }
        let threshold = options.threshold ?? 0.5
        let success = camera.registerCustomClassifier(modelAssetPath: modelAssetPath, labels: labels, threshold: Float(threshold))
        completion(.success(success))
    }

    public func setFlash(on: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.setFlash(on: on)
        completion(.success(true))
    }

    public func setZoom(level: Double, completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.setZoom(level: level)
        completion(.success(true))
    }

    public func flipCamera(completion: @escaping (Result<Bool, Error>) -> Void) {
        camera.flipCamera()
        if textureId != -1 { registrar?.textures().unregisterTexture(textureId) }
        textureId = registrar?.textures().register(camera) ?? -1
        completion(.success(true))
    }

    public func takePhoto(fileName: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        camera.takePhoto(fileName: fileName) { path in
            completion(.success(path))
        }
    }

    public func startVideoRecording(fileName: String?, completion: @escaping (Result<String?, Error>) -> Void) {
        camera.startVideoRecording(fileName: fileName) { path in
            completion(.success(path))
        }
    }

    public func stopVideoRecording(completion: @escaping (Result<String?, Error>) -> Void) {
        camera.stopVideoRecording { path in
            completion(.success(path))
        }
    }

    public func applyCameraFilterShader(shaderType: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let success = camera.applyCameraFilterShader(shaderType: shaderType)
        completion(.success(success))
    }

    // ==================== AudioApi Implementation ====================
    public func startAudio(options: BasicAudioOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Microphone permission is required.", details: nil)))
            return
        }
        audio.setFFTEnabled(options.enableFFT ?? false)
        audio.setStreamBytes(options.streamBytes ?? false)
        audio.setUpdateIntervalMs(Int(options.updateIntervalMs ?? 80))
        completion(.success(audio.start()))
    }

    public func startAudioWithOptions(options: NexoraAudioOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        let success = audio.start(enableFFT: false, streamBytes: false, interval: 80.0)
        completion(.success(success))
    }

    public func stopAudio(completion: @escaping (Result<Bool, Error>) -> Void) {
        audio.stop()
        completion(.success(true))
    }

    public func routeAudioOutput(route: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            if route == "speakerphone" {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }

    public func getAudioVolume(completion: @escaping (Result<Double, Error>) -> Void) {
        completion(.success(Double(AVAudioSession.sharedInstance().outputVolume)))
    }

    public func setAudioVolume(level: Double, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    public func selectAudioInput(device: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let session = AVAudioSession.sharedInstance()
        if let inputs = session.availableInputs {
            for input in inputs {
                if device == "bluetoothMic" && input.portType == .bluetoothHFP {
                    do {
                        try session.setPreferredInput(input)
                        completion(.success(true))
                        return
                    } catch {
                        completion(.failure(error))
                        return
                    }
                }
            }
        }
        completion(.success(true))
    }

    public func setAudioGain(gain: Double, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let session = AVAudioSession.sharedInstance()
            if session.isInputGainSettable {
                try session.setInputGain(Float(gain))
            }
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }

    // ==================== LocationApi Implementation ====================
    public func startLocation(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard hasLocationPermission() else {
            completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Location permission is required.", details: nil)))
            return
        }
        location.startUpdates()
        completion(.success(true))
    }

    public func startLocationWithOptions(options: NexoraLocationOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard hasLocationPermission() else {
            completion(.failure(PigeonError(code: "PERMISSION_DENIED", message: "Location permission is required.", details: nil)))
            return
        }
        location.startUpdates()
        completion(.success(true))
    }

    public func stopLocation(completion: @escaping (Result<Bool, Error>) -> Void) {
        location.stopUpdates()
        completion(.success(true))
    }

    public func setBackgroundLocationEnabled(enabled: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        location.setBackgroundEnabled(enabled)
        completion(.success(true))
    }

    // ==================== SensorApi Implementation ====================
    public func startSensor(frequencyHz: Int64, completion: @escaping (Result<Bool, Error>) -> Void) {
        sensors.start(frequencyHz: Int(frequencyHz))
        completion(.success(true))
    }

    public func startSensorWithOptions(options: NexoraSensorOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        sensors.start(frequencyHz: Int(options.frequencyHz ?? 60))
        completion(.success(true))
    }

    public func stopSensor(completion: @escaping (Result<Bool, Error>) -> Void) {
        sensors.stop()
        completion(.success(true))
    }

    public func enableDeadReckoning(enabled: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        location.enableDeadReckoning(enabled)
        completion(.success(true))
    }

    // ==================== BiometricsApi Implementation ====================
    public func authenticate(reason: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        biometrics.authenticate(reason: reason) { success in
            completion(.success(success))
        }
    }

    public func authenticateWithOptions(options: NexoraBiometricOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        biometrics.authenticate(reason: options.title ?? "Authentication Required") { success in
            completion(.success(success))
        }
    }

    public func canAuthenticate(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(biometrics.canAuthenticate()))
    }

    // ==================== BluetoothApi Implementation ====================
    public func startBluetoothScan(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard bluetooth.startScan() else {
            completion(.failure(PigeonError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is not powered on or not authorized.", details: nil)))
            return
        }
        completion(.success(true))
    }

    public func startBluetoothScanWithOptions(options: NexoraBluetoothScanOptions, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard bluetooth.startScan() else {
            completion(.failure(PigeonError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is not powered on or not authorized.", details: nil)))
            return
        }
        completion(.success(true))
    }

    public func stopBluetoothScan(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(bluetooth.stopScan()))
    }

    public func connectDevice(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard bluetooth.connect(deviceId: id) else {
            completion(.failure(PigeonError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is unavailable or the device id is invalid.", details: nil)))
            return
        }
        completion(.success(true))
    }

    public func disconnectDevice(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.disconnect()
        completion(.success(true))
    }

    public func discoverServices(deviceId: String, completion: @escaping (Result<[String?], Error>) -> Void) {
        bluetooth.discoverServices(deviceId: deviceId) { services in
            completion(.success(services ?? []))
        }
    }

    public func sendData(deviceId: String, serviceId: String, charId: String, data: [Int64?], completion: @escaping (Result<Bool, Error>) -> Void) {
        let bytes = Data(data.compactMap { $0 }.map { UInt8($0 & 0xFF) })
        guard bluetooth.sendData(deviceId: deviceId, serviceId: serviceId, charId: charId, data: bytes) else {
            completion(.failure(PigeonError(code: "BLUETOOTH_WRITE_FAILED", message: "Unable to write to the requested BLE characteristic.", details: nil)))
            return
        }
        completion(.success(true))
    }

    public func readData(deviceId: String, serviceId: String, charId: String, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
        guard bluetooth.readData(deviceId: deviceId, serviceId: serviceId, charId: charId, callback: { data in
            if let data = data {
                completion(.success(FlutterStandardTypedData(bytes: data)))
            } else {
                completion(.success(nil))
            }
        }) else {
            completion(.failure(PigeonError(code: "BLUETOOTH_READ_FAILED", message: "Unable to read from the requested BLE characteristic.", details: nil)))
            return
        }
    }

    public func subscribeToCharacteristic(deviceId: String, serviceId: String, charId: String, enable: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
            if let error = res as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = res as? Bool {
                completion(.success(success))
            } else {
                completion(.success(true))
            }
        }
    }

    public func requestMtu(deviceId: String, mtu: Int64, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    public func startBlePeripheral(uuid: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let success = blePeripheral.startAdvertising(uuid: uuid)
        completion(.success(success))
    }

    public func stopBlePeripheral(completion: @escaping (Result<Void, Error>) -> Void) {
        blePeripheral.stopAdvertising()
        completion(.success(()))
    }

    // ==================== SecureStorageApi Implementation ====================
    public func getStorageInfo(completion: @escaping (Result<NexoraStorageInfo?, Error>) -> Void) {
        let dict = storage.getStorageInfo()
        let info = NexoraStorageInfo(
            internalTotal: dict["internalTotal"] as? Int64,
            internalFree: dict["internalFree"] as? Int64,
            externalTotal: dict["externalTotal"] as? Int64,
            externalFree: dict["externalFree"] as? Int64,
            appCacheSize: dict["appCacheSize"] as? Int64,
            appDataSize: dict["appDataSize"] as? Int64
        )
        completion(.success(info))
    }

    public func writeFile(fileName: String, content: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let res = storage.writeFile(fileName: fileName, content: content)
        completion(.success(res))
    }

    public func appendFile(fileName: String, content: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let res = storage.appendFile(fileName: fileName, content: content)
        completion(.success(res))
    }

    public func readFile(fileName: String, completion: @escaping (Result<String?, Error>) -> Void) {
        let res = storage.readFile(fileName: fileName)
        completion(.success(res))
    }

    public func deleteFile(fileName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let res = storage.deleteFile(fileName: fileName)
        completion(.success(res))
    }

    public func fileExists(fileName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let res = storage.fileExists(fileName: fileName)
        completion(.success(res))
    }

    public func listFiles(completion: @escaping (Result<[NexoraFileInfo?], Error>) -> Void) {
        let files = storage.listFiles()
        var fileInfos: [NexoraFileInfo?] = []
        for file in files {
            if let f = file as? [String: Any] {
                fileInfos.append(NexoraFileInfo(
                    name: f["name"] as? String,
                    size: f["size"] as? Int64,
                    isDirectory: f["isDirectory"] as? Bool,
                    lastModifiedMs: f["lastModifiedMs"] as? Int64
                ))
            }
        }
        completion(.success(fileInfos))
    }

    public func writeBytes(fileName: String, bytes: FlutterStandardTypedData, completion: @escaping (Result<String?, Error>) -> Void) {
        let res = storage.writeBytes(fileName: fileName, bytes: bytes)
        completion(.success(res))
    }

    public func readBytes(fileName: String, completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
        let res = storage.readBytes(fileName: fileName)
        completion(.success(res))
    }

    public func clearCache(completion: @escaping (Result<Bool, Error>) -> Void) {
        let res = storage.clearCache()
        completion(.success(res))
    }

    public func getAppDirectory(completion: @escaping (Result<String?, Error>) -> Void) {
        completion(.success(storage.getAppDirectory()))
    }

    public func getCacheDirectory(completion: @escaping (Result<String?, Error>) -> Void) {
        completion(.success(storage.getCacheDirectory()))
    }

    public func getExternalDirectory(completion: @escaping (Result<String?, Error>) -> Void) {
        completion(.success(storage.getExternalDirectory()))
    }

    // ==================== SystemApi Implementation ====================
    public func configureSdk(config: NexoraSdkConfig, completion: @escaping (Result<Bool, Error>) -> Void) {
        logNativeCalls = config.enableLogging ?? false
        ecoModeUserEnabled = config.ecoMode ?? false
        completion(.success(true))
    }

    public func requestPermissions(completion: @escaping (Result<Bool, Error>) -> Void) {
        if permissionResult != nil {
            completion(.failure(PigeonError(code: "PERMISSION_REQUEST_IN_PROGRESS", message: "A permission request is already running.", details: nil)))
            return
        }

        permissionResult = { res in
            if let success = res as? Bool {
                completion(.success(success))
            } else if let error = res as? Error {
                completion(.failure(error))
            } else {
                completion(.success(false))
            }
        }
        pendingPermissionType = nil
        let group = DispatchGroup()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            pendingCameraPermission = true
        case .notDetermined:
            group.enter()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                self.pendingCameraPermission = granted
                group.leave()
            }
        default:
            pendingCameraPermission = false
        }

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            pendingMicrophonePermission = true
        case .undetermined:
            group.enter()
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                self.pendingMicrophonePermission = granted
                group.leave()
            }
        default:
            pendingMicrophonePermission = false
        }

        group.notify(queue: .main) {
            let status = CLLocationManager.authorizationStatus()
            if status == .notDetermined {
                let manager = CLLocationManager()
                self.permissionLocationManager = manager
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
            } else {
                self.finishNativePermissionRequest()
            }
        }
    }

    public func requestPermission(type: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if permissionResult != nil {
            completion(.failure(PigeonError(code: "PERMISSION_REQUEST_IN_PROGRESS", message: "A permission request is already running.", details: nil)))
            return
        }

        let resultWrapper: (Any?) -> Void = { res in
            if let success = res as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }

        switch type {
        case "camera":
            requestCameraPermission(result: resultWrapper)
        case "audio":
            requestAudioPermission(result: resultWrapper)
        case "location":
            pendingPermissionType = type
            permissionResult = resultWrapper
            let status = CLLocationManager.authorizationStatus()
            if status == .notDetermined {
                let manager = CLLocationManager()
                permissionLocationManager = manager
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
            } else {
                finishNativePermissionRequest()
            }
        case "bluetooth":
            completion(.success(hasBluetoothPermission()))
        default:
            completion(.failure(PigeonError(code: "INVALID_ARGUMENT", message: "Unknown permission type: \(type)", details: nil)))
        }
    }

    public func getPermissionStatus(type: String, completion: @escaping (Result<NexoraPermissionStatus, Error>) -> Void) {
        let dict = getPermissionStatus(type: type)
        let status = NexoraPermissionStatus(
            permission: dict["permission"] as? String,
            state: dict["state"] as? String,
            canRequest: dict["canRequest"] as? Bool
        )
        completion(.success(status))
    }

    public func openAppSettings(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            completion(.success(false))
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            completion(.success(success))
        }
    }

    public func getDeviceInfo(completion: @escaping (Result<NexoraDeviceInfo, Error>) -> Void) {
        let dict = getDeviceInfo()
        let info = NexoraDeviceInfo(
            platform: dict["platform"] as? String,
            manufacturer: dict["manufacturer"] as? String,
            model: dict["model"] as? String,
            osVersion: dict["osVersion"] as? String,
            sdkVersion: dict["sdkVersion"] as? String,
            isPhysicalDevice: dict["isPhysicalDevice"] as? Bool,
            totalRamBytes: dict["totalRamBytes"] as? Int64,
            availableRamBytes: dict["availableRamBytes"] as? Int64,
            cpuArchitecture: dict["cpuArchitecture"] as? String,
            screenRefreshRate: dict["screenRefreshRate"] as? Double,
            thermalState: dict["thermalState"] as? String
        )
        completion(.success(info))
    }

    public func getConnectivityInfo(completion: @escaping (Result<NexoraConnectivityInfo, Error>) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.nexora.sdk.connectivity")
        var didReturn = false

        monitor.pathUpdateHandler = { path in
            guard !didReturn else { return }
            didReturn = true
            monitor.cancel()

            let networkType: String
            if path.usesInterfaceType(.wifi) {
                networkType = "wifi"
            } else if path.usesInterfaceType(.cellular) {
                networkType = "mobile"
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkType = "ethernet"
            } else if path.usesInterfaceType(.loopback) {
                networkType = "loopback"
            } else {
                networkType = path.status == .satisfied ? "unknown" : "none"
            }

            let info = NexoraConnectivityInfo(
                isConnected: path.status == .satisfied,
                networkType: networkType,
                isMetered: path.isExpensive,
                isVpn: false,
                signalStrength: nil,
                ipAddress: nil
            )
            DispatchQueue.main.async {
                completion(.success(info))
            }
        }

        monitor.start(queue: queue)
    }

    public func getBatteryInfo(completion: @escaping (Result<NexoraBatteryInfo?, Error>) -> Void) {
        if let dict = health.getBatteryInfo() as? [String: Any] {
            let info = NexoraBatteryInfo(
                level: dict["level"] as? Double,
                isCharging: dict["isCharging"] as? Bool,
                status: dict["status"] as? String,
                temperature: dict["temperature"] as? Double
            )
            completion(.success(info))
        } else {
            completion(.success(nil))
        }
    }

    public func getWifiInfo(completion: @escaping (Result<NexoraWifiInfo?, Error>) -> Void) {
        if let dict = health.getWifiInfo() as? [String: Any] {
            let info = NexoraWifiInfo(
                ssid: dict["ssid"] as? String,
                bssid: dict["bssid"] as? String,
                signalStrength: dict["signalStrength"] as? Int64,
                frequency: dict["frequency"] as? Int64,
                linkSpeed: dict["linkSpeed"] as? Int64
            )
            completion(.success(info))
        } else {
            completion(.success(nil))
        }
    }

    public func vibrate(durationMs: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        feedback.vibrate(duration: Int(durationMs))
        completion(.success(()))
    }

    public func hapticFeedback(type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        feedback.haptic(type: type)
        completion(.success(()))
    }

    public func performHapticWithOptions(options: NexoraHapticOptions, completion: @escaping (Result<Void, Error>) -> Void) {
        feedback.haptic(type: options.type ?? "medium")
        completion(.success(()))
    }

    public func copyText(text: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        UIPasteboard.general.string = text
        completion(.success(true))
    }

    public func pasteText(completion: @escaping (Result<String?, Error>) -> Void) {
        completion(.success(UIPasteboard.general.string))
    }

    public func openUrl(url: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let nsUrl = URL(string: url) else {
            completion(.success(false))
            return
        }
        UIApplication.shared.open(nsUrl, options: [:]) { success in
            completion(.success(success))
        }
    }

    public func shareText(text: String, subject: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        var items: [Any] = [text]
        if let subject = subject, !subject.isEmpty {
            items.append(subject)
        }
        DispatchQueue.main.async {
            guard let controller = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
                completion(.success(false))
                return
            }
            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            controller.present(activity, animated: true) {
                completion(.success(true))
            }
        }
    }

    public func saveToGallery(filePath: String, completion: @escaping (Result<String?, Error>) -> Void) {
        storage.saveToGallery(filePath: filePath) { path in
            completion(.success(path))
        }
    }

    public func enterPictureInPicture(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }

    public func getConnectedUsbDevices(completion: @escaping (Result<[String?], Error>) -> Void) {
        completion(.success([]))
    }

    public func startForegroundService(title: String, content: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    public func updateForegroundService(title: String, text: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    public func stopForegroundService(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }

    public func enableSmartSync(uploadEndpointUrl: String, headers: [String?: String?], rollLimitBytes: Int64, requireWifi: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        var cleanHeaders: [String: String] = [:]
        for (key, val) in headers {
            if let k = key, let v = val {
                cleanHeaders[k] = v
            }
        }
        SmartSyncManager.shared.enable(url: uploadEndpointUrl, headers: cleanHeaders, limit: Int(rollLimitBytes), wifiOnly: requireWifi)
        completion(.success(true))
    }

    public func setEcoModeEnabled(enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        ecoModeUserEnabled = enabled
        completion(.success(()))
    }

    public func isEcoModeActive(completion: @escaping (Result<Bool, Error>) -> Void) {
        let active = ecoModeUserEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
        completion(.success(active))
    }

    public func getThermalState(completion: @escaping (Result<String, Error>) -> Void) {
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            completion(.success("normal"))
        case .fair:
            completion(.success("fair"))
        case .serious:
            completion(.success("serious"))
        case .critical:
            completion(.success("critical"))
        @unknown default:
            completion(.success("unknown"))
        }
    }
}
