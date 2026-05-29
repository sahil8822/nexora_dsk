import Flutter
import UIKit
import AVFoundation
import CoreLocation
import CoreBluetooth
import Network

/// Nexora SDK v3.1.2 — Complete iOS Plugin with all method handlers.
public class NexoraSdk: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private let camera = HardwareCameraManager()
    private let audio = HardwareAudioManager()
    private let sensors = HardwareSensorManager()
    private let bluetooth = HardwareBluetoothManager()
    private let location = HardwareLocationManager()
    private let biometrics = HardwareBiometricManager()
    private let feedback = HardwareFeedbackManager()
    private let health = HardwareHealthManager()
    private let storage = HardwareStorageManager()
    private let nfc = HardwareNfcManager()
    private var ecoModeUserEnabled = false
    private var sdkConfig: [String: Any] = [:]
    private var logNativeCalls = false
    private var iosOptions: [String: Any] = [:]
    
    private var registrar: FlutterPluginRegistrar?
    private var textureId: Int64 = -1
    private var permissionResult: FlutterResult?
    private var permissionLocationManager: CLLocationManager?
    private var pendingCameraPermission = false
    private var pendingMicrophonePermission = false
    private var pendingPermissionType: String?

    public override init() {
        super.init()
        health.setSmartSyncManager(SmartSyncManager.shared)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NexoraSdk()
        instance.registrar = registrar

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
            sdk?.location.setEventSink(nil)
            sdk?.sensors.setEventSink(nil)
            sdk?.audio.setEventSink(nil)
            sdk?.nfc.setEventSink(nil)
            return nil
        }
    }

    private var eventSink: FlutterEventSink?

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

    private func shouldRunInBackground(_ method: String) -> Bool {
        switch method {
        case "getStorageInfo", "writeFile", "appendFile", "readFile", "deleteFile", "fileExists",
             "listFiles", "writeBytes", "readBytes", "clearCache", "getAppDirectory", "getCacheDirectory", "getExternalDirectory",
             "writeSecureFile", "readSecureFile", "deleteSecureFile",
             "startBluetoothScan", "startBluetoothScanWithOptions", "stopBluetoothScan", "connectDevice",
             "disconnectDevice", "discoverServices", "sendData", "readData",
             "startLogging", "stopLogging", "addGeofence",
             "enableSmartSync", "enableDeadReckoning",
             "getBatteryInfo", "getWifiInfo", "getDeviceInfo", "getConnectivityInfo":
            return true
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            return false
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if shouldRunInBackground(call.method) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.handleSafe(call, result: result)
            }
        } else {
            self.handleSafe(call, result: result)
        }
    }

    private func handleSafe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        if logNativeCalls {
            NSLog("NexoraSdk native call: \(call.method)")
        }

        switch call.method {
        case "configureSdk":
            sdkConfig = args ?? [:]
            logNativeCalls = sdkConfig["logNativeCalls"] as? Bool ?? false
            iosOptions = sdkConfig["ios"] as? [String: Any] ?? [:]
            applyIosOptions(iosOptions)
            result(true)

        // ==================== Camera & Vision ====================
        case "startCamera":
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission is required.", details: nil))
                return
            }
            textureId = registrar?.textures().register(camera) ?? -1
            camera.start(width: args?["width"] as? Int ?? 1280, height: args?["height"] as? Int ?? 720)
            result(textureId)

        case "stopCamera":
            camera.stop()
            if textureId != -1 { registrar?.textures().unregisterTexture(textureId) }
            textureId = -1
            result(true)

        case "setVisionMode":
            camera.setVisionMode(face: args?["face"] as? Bool ?? false, barcode: args?["barcode"] as? Bool ?? false)
            result(true)

        case "registerCustomClassifier":
            guard let modelAssetPath = args?["modelAssetPath"] as? String,
                  let labels = args?["labels"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "registerCustomClassifier requires modelAssetPath and labels.", details: nil))
                return
            }
            let threshold = args?["threshold"] as? Double ?? 0.5
            let success = camera.registerCustomClassifier(modelAssetPath: modelAssetPath, labels: labels, threshold: Float(threshold))
            result(success)

        case "startCameraWithOptions":
            textureId = registrar?.textures().register(camera) ?? -1
            let size = cameraSize(for: args?["resolution"] as? String)
            camera.start(width: size.width, height: size.height)
            result(textureId)

        case "startAudioWithOptions":
            let success = audio.start(enableFFT: false, streamBytes: false, interval: 80.0)
            result(success)

        case "enableSmartSync":
            guard let uploadEndpointUrl = args?["uploadEndpointUrl"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "enableSmartSync requires uploadEndpointUrl.", details: nil))
                return
            }
            let headers = args?["headers"] as? [String: String] ?? [:]
            let rollLimitBytes = args?["rollLimitBytes"] as? Int ?? (2 * 1024 * 1024)
            let requireWifi = args?["requireWifi"] as? Bool ?? true
            SmartSyncManager.shared.enable(url: uploadEndpointUrl, headers: headers, limit: rollLimitBytes, wifiOnly: requireWifi)
            result(true)

        case "applyCameraFilterShader":
            guard let shaderType = args?["shaderType"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "applyCameraFilterShader requires shaderType.", details: nil))
                return
            }
            result(camera.applyCameraFilterShader(shaderType: shaderType))

        case "enableDeadReckoning":
            let enabled = args?["enabled"] as? Bool ?? false
            location.enableDeadReckoning(enabled)
            result(true)

        case "setFlash":
            camera.setFlash(on: args?["on"] as? Bool ?? false)
            result(true)

        case "setZoom":
            camera.setZoom(level: args?["level"] as? Double ?? 1.0)
            result(true)

        case "flipCamera":
            camera.flipCamera()
            // Re-register texture after flip
            if textureId != -1 { registrar?.textures().unregisterTexture(textureId) }
            textureId = registrar?.textures().register(camera) ?? -1
            result(true)

        case "takePhoto":
            camera.takePhoto(fileName: args?["fileName"] as? String) { path in
                if let path = path {
                    result(path)
                } else {
                    result(FlutterError(code: "CAMERA_UNAVAILABLE", message: "Camera is not running or photo capture failed.", details: nil))
                }
            }

        case "startVideoRecording":
            camera.startVideoRecording(fileName: args?["fileName"] as? String) { path in
                if let path = path {
                    result(path)
                } else {
                    result(FlutterError(code: "CAMERA_ERROR", message: "Failed to start video recording.", details: nil))
                }
            }

        case "stopVideoRecording":
            camera.stopVideoRecording { path in
                if let path = path {
                    result(path)
                } else {
                    result(FlutterError(code: "CAMERA_ERROR", message: "Failed to stop video recording.", details: nil))
                }
            }

        // ==================== Audio & FFT ====================
        case "startAudio":
            guard AVAudioSession.sharedInstance().recordPermission == .granted else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission is required.", details: nil))
                return
            }
            audio.setFFTEnabled(args?["enableFFT"] as? Bool ?? false)
            audio.setStreamBytes(args?["streamBytes"] as? Bool ?? false)
            audio.setUpdateIntervalMs(args?["updateIntervalMs"] as? Int ?? 80)
            result(audio.start())

        case "stopAudio":
            audio.stop()
            result(true)

        case "routeAudioOutput":
            let route = args?["route"] as? String ?? "defaultRoute"
            do {
                if route == "speakerphone" {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                } else {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                }
                result(true)
            } catch {
                result(FlutterError(code: "AUDIO_ROUTE_FAILED", message: error.localizedDescription, details: nil))
            }

        case "getAudioVolume":
            result(Double(AVAudioSession.sharedInstance().outputVolume))

        case "setAudioVolume":
            result(true)

        case "selectAudioInput":
            let targetDevice = args?["device"] as? String ?? "defaultMic"
            let session = AVAudioSession.sharedInstance()
            if let inputs = session.availableInputs {
                for input in inputs {
                    if targetDevice == "bluetoothMic" && input.portType == .bluetoothHFP {
                        do {
                            try session.setPreferredInput(input)
                            result(true)
                            return
                        } catch {}
                    }
                }
            }
            result(true)

        case "setAudioGain":
            let gain = args?["gain"] as? Double ?? 1.0
            do {
                let session = AVAudioSession.sharedInstance()
                if session.isInputGainSettable {
                    try session.setInputGain(Float(gain))
                }
                result(true)
            } catch {
                result(FlutterError(code: "AUDIO_GAIN_FAILED", message: error.localizedDescription, details: nil))
            }

        case "setEcoModeEnabled":
            let enabled = args?["enabled"] as? Bool ?? false
            ecoModeUserEnabled = enabled
            result(nil)

        case "isEcoModeActive":
            let active = ecoModeUserEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
            result(active)

        case "getThermalState":
            let state = ProcessInfo.processInfo.thermalState
            switch state {
            case .nominal:
                result("normal")
            case .fair:
                result("fair")
            case .serious:
                result("serious")
            case .critical:
                result("critical")
            @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
                result("normal")
            }

        // ==================== Bluetooth ====================
        case "startBluetoothScan":
            guard bluetooth.startScan() else {
                result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is not powered on or not authorized.", details: nil))
                return
            }
            result(true)

        case "startBluetoothScanWithOptions":
            guard bluetooth.startScan() else {
                result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is not powered on or not authorized.", details: nil))
                return
            }
            result(true)

        case "stopBluetoothScan":
            result(bluetooth.stopScan())

        case "connectDevice":
            guard bluetooth.connect(deviceId: args?["id"] as? String ?? "") else {
                result(FlutterError(code: "BLUETOOTH_UNAVAILABLE", message: "Bluetooth is unavailable or the device id is invalid.", details: nil))
                return
            }
            result(true)

        case "disconnectDevice":
            bluetooth.disconnect()
            result(true)

        case "discoverServices":
            bluetooth.discoverServices(deviceId: args?["id"] as? String ?? "") { services in
                result(services)
            }

        case "sendData":
            let deviceId = args?["deviceId"] as? String ?? ""
            let serviceId = args?["serviceId"] as? String ?? ""
            let charId = args?["charId"] as? String ?? ""
            let dataArray = args?["data"] as? [Int] ?? []
            let bytes = Data(dataArray.map { UInt8($0 & 0xFF) })
            guard bluetooth.sendData(deviceId: deviceId, serviceId: serviceId, charId: charId, data: bytes) else {
                result(FlutterError(code: "BLUETOOTH_WRITE_FAILED", message: "Unable to write to the requested BLE characteristic.", details: nil))
                return
            }
            result(true)

        case "readData":
            let deviceId = args?["deviceId"] as? String ?? ""
            let serviceId = args?["serviceId"] as? String ?? ""
            let charId = args?["charId"] as? String ?? ""
            guard bluetooth.readData(deviceId: deviceId, serviceId: serviceId, charId: charId, callback: { data in
                if let data = data {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(nil)
                }
            }) else {
                result(FlutterError(code: "BLUETOOTH_READ_FAILED", message: "Unable to read from the requested BLE characteristic.", details: nil))
                return
            }

        // ==================== Location & Geofencing ====================
        case "startLocation":
            guard hasLocationPermission() else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission is required.", details: nil))
                return
            }
            location.startUpdates()
            result(true)

        case "startLocationWithOptions":
            guard hasLocationPermission() else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission is required.", details: nil))
                return
            }
            location.startUpdates()
            result(true)

        case "stopLocation":
            location.stopUpdates()
            result(true)

        case "setBackgroundLocationEnabled":
            location.setBackgroundEnabled(args?["enabled"] as? Bool ?? false)
            result(true)

        case "addGeofence":
            guard hasLocationPermission() else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Location permission is required.", details: nil))
                return
            }
            guard let id = args?["id"] as? String,
                  let lat = args?["lat"] as? Double,
                  let lon = args?["lon"] as? Double,
                  let radius = args?["radius"] as? Double,
                  !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  radius > 0 else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Geofence requires id, lat, lon, and a positive radius.", details: nil))
                return
            }
            result(location.addGeofence(id: id, lat: lat, lon: lon, radius: radius))

        // ==================== Sensors ====================
        case "startSensor":
            sensors.start(frequencyHz: args?["frequency"] as? Int ?? 60)
            result(true)

        case "startSensorWithOptions":
            sensors.start(frequencyHz: sensorFrequency(for: args?["accuracy"] as? String))
            result(true)

        case "stopSensor":
            sensors.stop()
            result(true)

        // ==================== Biometrics ====================
        case "authenticate":
            biometrics.authenticate(reason: args?["reason"] as? String ?? "Authentication Required") { success in
                result(success)
            }

        case "authenticateWithOptions":
            let title = args?["title"] as? String ?? "Authentication Required"
            biometrics.authenticate(reason: title) { success in
                result(success)
            }

        case "canAuthenticate":
            result(biometrics.canAuthenticate())

        // ==================== Feedback ====================
        case "vibrate":
            feedback.vibrate(duration: args?["duration"] as? Int ?? 50)
            result(nil)

        case "hapticFeedback":
            feedback.haptic(type: args?["type"] as? String ?? "impact")
            result(nil)

        case "performHapticWithOptions":
            let type = args?["type"] as? String ?? "medium"
            feedback.haptic(type: type)
            result(nil)

        // ==================== Health ====================
        case "getBatteryInfo":
            result(health.getBatteryInfo())

        case "getWifiInfo":
            result(health.getWifiInfo())

        case "startLogging":
            result(
                health.startLogging(
                    fileName: args?["fileName"] as? String ?? "log.csv",
                    interval: args?["interval"] as? Double ?? 1000.0
                )
            )

        case "stopLogging":
            health.stopLogging()
            result(true)

        // ==================== Storage ====================
        case "getStorageInfo":
            result(storage.getStorageInfo())

        case "writeFile":
            result(storage.writeFile(fileName: args?["fileName"] as? String ?? "", content: args?["content"] as? String ?? ""))

        case "appendFile":
            result(storage.appendFile(fileName: args?["fileName"] as? String ?? "", content: args?["content"] as? String ?? ""))

        case "readFile":
            result(storage.readFile(fileName: args?["fileName"] as? String ?? ""))

        case "deleteFile":
            result(storage.deleteFile(fileName: args?["fileName"] as? String ?? ""))

        case "fileExists":
            result(storage.fileExists(fileName: args?["fileName"] as? String ?? ""))

        case "listFiles":
            result(storage.listFiles())

        case "writeBytes":
            if let bytes = args?["bytes"] as? FlutterStandardTypedData {
                result(storage.writeBytes(fileName: args?["fileName"] as? String ?? "", bytes: bytes))
            } else {
                result(nil)
            }

        case "readBytes":
            result(storage.readBytes(fileName: args?["fileName"] as? String ?? ""))

        case "clearCache":
            result(storage.clearCache())

        case "getAppDirectory":
            result(storage.getAppDirectory())

        case "getCacheDirectory":
            result(storage.getCacheDirectory())

        case "getExternalDirectory":
            result(storage.getExternalDirectory())

        // ==================== NFC ====================
        case "startNfcScan":
            result(nfc.startScan())

        case "stopNfcScan":
            result(nfc.stopScan())

        case "writeNdefRecord":
            guard let type = args?["type"] as? String,
                  let payload = args?["payload"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "writeNdefRecord requires type and payload.", details: nil))
                return
            }
            nfc.writeNdef(type: type, payload: payload) { success in
                result(success)
            }

        // ==================== Secure Storage ====================
        case "writeSecureFile":
            guard let fileName = args?["fileName"] as? String,
                  let content = args?["content"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "writeSecureFile requires fileName and content.", details: nil))
                return
            }
            result(storage.writeSecureFile(fileName: fileName, content: content))

        case "readSecureFile":
            guard let fileName = args?["fileName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "readSecureFile requires fileName.", details: nil))
                return
            }
            result(storage.readSecureFile(fileName: fileName))

        case "deleteSecureFile":
            guard let fileName = args?["fileName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "deleteSecureFile requires fileName.", details: nil))
                return
            }
            result(storage.deleteSecureFile(fileName: fileName))

        // ==================== Base ====================
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "getDeviceInfo":
            result(getDeviceInfo())

        case "getConnectivityInfo":
            getConnectivityInfo(result: result)

        case "getPermissionStatus":
            result(getPermissionStatus(type: args?["type"] as? String))

        case "openAppSettings":
            openAppSettings(result: result)

        case "copyText":
            UIPasteboard.general.string = args?["text"] as? String ?? ""
            result(true)

        case "pasteText":
            result(UIPasteboard.general.string)

        case "openUrl":
            openUrl(args?["url"] as? String ?? "", result: result)

        case "shareText":
            shareText(args?["text"] as? String ?? "", subject: args?["subject"] as? String, result: result)

        case "requestPermissions":
            requestNativePermissions(result: result)

        case "requestPermission":
            requestNativePermission(type: args?["type"] as? String, result: result)

        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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

    private func requestNativePermissions(result: @escaping FlutterResult) {
        if permissionResult != nil {
            result(FlutterError(code: "PERMISSION_REQUEST_IN_PROGRESS", message: "A permission request is already running.", details: nil))
            return
        }

        permissionResult = result
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
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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

    private func requestNativePermission(type: String?, result: @escaping FlutterResult) {
        if permissionResult != nil {
            result(FlutterError(code: "PERMISSION_REQUEST_IN_PROGRESS", message: "A permission request is already running.", details: nil))
            return
        }

        switch type {
        case "camera":
            requestCameraPermission(result: result)
        case "audio":
            requestAudioPermission(result: result)
        case "location":
            pendingPermissionType = type
            permissionResult = result
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
            result(hasBluetoothPermission())
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Unknown permission type: \(type ?? "nil")", details: nil))
        }
    }

    private func requestCameraPermission(result: @escaping FlutterResult) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            result(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { result(granted) }
            }
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            result(false)
        }
    }

    private func requestAudioPermission(result: @escaping FlutterResult) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            result(true)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async { result(granted) }
            }
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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

    private func getPermissionStatus(type: String?) -> [String: Any] {
        let permission = type ?? "unknown"
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
            @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
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
            @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
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
            @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
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
                @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
                    state = "unsupported"
                    canRequest = false
                }
            } else {
                state = "granted"
                canRequest = false
            }
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

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

    private func openAppSettings(result: @escaping FlutterResult) {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            result(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            result(success)
        }
    }

    private func openUrl(_ urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            result(success)
        }
    }

    private func shareText(_ text: String, subject: String?, result: @escaping FlutterResult) {
        var items: [Any] = [text]
        if let subject = subject, !subject.isEmpty {
            items.append(subject)
        }
        guard let controller = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            result(false)
            return
        }
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.present(activity, animated: true) {
            result(true)
        }
    }

    private func getDeviceInfo() -> [String: Any] {
        let processInfo = ProcessInfo.processInfo
        let thermalState: String
        switch processInfo.thermalState {
        case .nominal:
            thermalState = "nominal"
        case .fair:
            thermalState = "fair"
        case .serious:
            thermalState = "serious"
        case .critical:
            thermalState = "critical"
        @unknown 
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            thermalState = "unknown"
        }

        #if targetEnvironment(simulator)
        let isPhysicalDevice = false
        #else
        let isPhysicalDevice = true
        #endif

        return [
            "platform": "ios",
            "manufacturer": "Apple",
            "model": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion,
            "sdkVersion": processInfo.operatingSystemVersionString,
            "isPhysicalDevice": isPhysicalDevice,
            "totalRamBytes": Int64(processInfo.physicalMemory),
            "availableRamBytes": 0,
            "cpuArchitecture": cpuArchitecture(),
            "screenRefreshRate": Double(UIScreen.main.maximumFramesPerSecond),
            "thermalState": thermalState
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
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            return (1280, 720)
        }
    }

    private func sensorFrequency(for accuracy: String?) -> Int {
        switch accuracy {
        case "fastest":
            return 120
        case "game":
            return 100
        case "ui":
            return 60
        
        case "startForegroundService":
            // iOS background tasks are handled via Info.plist and Background Fetch, so this is mostly a no-op
            // but we can register a background task to keep the app alive slightly longer
            let title = args["title"] as? String ?? "Background Task"
            result(true)
            
        case "stopForegroundService":
            result(true)
            
        case "subscribeToCharacteristic":
            guard let deviceId = args["deviceId"] as? String,
                  let serviceId = args["serviceId"] as? String,
                  let charId = args["charId"] as? String,
                  let enable = args["enable"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            bluetooth.subscribeToCharacteristic(deviceId: deviceId, serviceId: serviceId, charId: charId, enable: enable) { res in
                result(res)
            }
            
        case "requestMtu":
            // iOS negotiates MTU automatically
            result(true)
            
        case "saveToGallery":
            guard let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing filePath", details: nil))
                return
            }
            storage.saveToGallery(filePath: filePath) { path in
                if let p = path {
                    result(p)
                } else {
                    result(FlutterError(code: "STORAGE_ERROR", message: "Failed to save to Gallery", details: nil))
                }
            }

        
        case "loadCustomModel":
            let path = args["modelPath"] as? String ?? ""
            result(ai.loadCustomModel(modelPath: path))
            
        case "runInference":
            let input = args["input"] as? [String: Any] ?? [:]
            result(ai.runInference(input: input))
            
        case "getConnectedUsbDevices":
            // USB OTG not fully supported on iOS without MFi
            result([])
            
        case "openUsbConnection", "writeUsbData":
            result(false)
            
        case "startDepthCamera":
            result(false)
            
        case "generateSecureKeyPair":
            let alias = args["alias"] as? String ?? ""
            result(crypto.generateSecureKeyPair(alias: alias))
            
        case "signData":
            guard let alias = args["alias"] as? String, let data = args["data"] as? FlutterStandardTypedData else {
                result(nil)
                return
            }
            if let signature = crypto.signData(alias: alias, data: data.data) {
                result(signature)
            } else {
                result(nil)
            }
            
        case "scheduleBackgroundTask":
            let taskId = args["taskId"] as? String ?? ""
            let interval = args["intervalSeconds"] as? Int ?? 900
            result(backgroundTasks.scheduleBackgroundTask(taskId: taskId, intervalSeconds: interval))

        default:
            return 30
        }
    }

    private func getConnectivityInfo(result: @escaping FlutterResult) {
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

            DispatchQueue.main.async {
                result([
                    "isConnected": path.status == .satisfied,
                    "networkType": networkType,
                    "isMetered": path.isExpensive,
                    "isVpn": false,
                    "signalStrength": nil,
                    "ipAddress": nil
                ])
            }
        }

        monitor.start(queue: queue)
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
}
