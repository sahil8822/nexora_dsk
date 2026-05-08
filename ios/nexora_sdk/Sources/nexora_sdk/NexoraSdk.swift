import Flutter
import UIKit
import AVFoundation
import CoreLocation
import CoreBluetooth

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
    
    private var registrar: FlutterPluginRegistrar?
    private var textureId: Int64 = -1
    private var permissionResult: FlutterResult?
    private var permissionLocationManager: CLLocationManager?
    private var pendingCameraPermission = false
    private var pendingMicrophonePermission = false
    private var pendingPermissionType: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NexoraSdk()
        instance.registrar = registrar

        let channel = FlutterMethodChannel(name: "nexora_sdk/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "nexora_sdk/events", binaryMessenger: registrar.messenger())
        let streamHandler = HardwareStreamHandler(
            camera: instance.camera,
            bluetooth: instance.bluetooth,
            location: instance.location,
            sensor: instance.sensors,
            audio: instance.audio
        )
        eventChannel.setStreamHandler(streamHandler)
    }

    deinit {
        releaseHardware()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
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

        // ==================== Bluetooth ====================
        case "startBluetoothScan":
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

        // ==================== Location & Geofencing ====================
        case "startLocation":
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

        case "stopSensor":
            sensors.stop()
            result(true)

        // ==================== Biometrics ====================
        case "authenticate":
            biometrics.authenticate(reason: args?["reason"] as? String ?? "Authentication Required") { success in
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

        // ==================== Base ====================
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "requestPermissions":
            requestNativePermissions(result: result)

        case "requestPermission":
            requestNativePermission(type: args?["type"] as? String, result: result)

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
}
